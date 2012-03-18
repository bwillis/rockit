require 'spec_helper'

describe Rockit::Application do
  before do
    @app = Rockit::Application.new({})
  end

  def block_should_execute
    block = Proc.new {}
    block.expects(:call).once
    block
  end

  def block_should_not_execute
    lambda { |*args| fail }
  end

  describe '#run' do
    context 'running without a configuration file available' do
      before do
        File.exists?('Rockitfile').should_not be
      end
      it 'does raises an argument error' do
        lambda{ @app.run }.should raise_error
      end
    end
    context 'running with a configuration file' do
      before do
        File.stubs(:exists?).returns(false)
        File.stubs(:exists?).with('Rockitfile.rb').returns(true)
        File.stubs(:read).with('Rockitfile.rb').returns("")
      end
      it 'does not raise an argument error' do
        lambda{ @app.run }.should_not raise_error
      end
    end
  end

  describe '#clear_cache' do
    context 'when calling clear cache' do
      before do
        @app.if_first_time &block_should_execute
        @app.if_first_time &block_should_not_execute
        @app.clear_cache
      end

      it 'resets cache for first time' do
        @app.if_first_time &block_should_execute
      end
    end
  end

  describe '#if_directory_changed' do
    before do
      Dir.stubs(:glob).returns(['file1', 'file2'])
    end
    context 'when not called before' do
      it 'executes the block' do
        @app.if_directory_changed('test', &block_should_execute)
      end
    end

    context 'when called before' do
      before do
        @app.if_directory_changed('test')
      end
      context 'and the dir has not changed' do
        it 'does not execute the block' do
          @app.if_directory_changed('test', &block_should_not_execute)
        end
      end

      context 'and the dir has changed' do
        before do
          Dir.unstub(:glob)
          Dir.stubs(:glob).returns(['file1', 'file2', 'file3'])
        end
        it 'does execute the block' do
          @app.if_directory_changed('test', &block_should_execute)
        end
      end
    end
  end

  describe '#if_first_time' do
    it 'runs the block the first time' do
      @app.if_first_time &block_should_execute
    end
    it 'does not run the block the second time' do
      @app.if_first_time {}
      @app.if_first_time &block_should_not_execute
    end
  end

  describe '#if_string_digest_changed' do
    context 'called when no previous digest exists' do
      it 'executes the block' do
        @app.if_string_digest_changed('fake', 'fake_out', &block_should_execute)
      end
    end

    context 'with a unchanged digest' do
      before do
        @app.if_string_digest_changed('fake', 'fake_out')
      end

      it 'does not executes the block' do
        @app.if_string_digest_changed('fake', 'fake_out', &block_should_not_execute)
      end
    end

    context 'with a changed digest' do
      before do
        @app.if_string_digest_changed('fake', 'old_digest')
      end

      it 'executes the block' do
        @app.if_string_digest_changed('fake', 'new_digest', &block_should_execute)
      end
    end
  end

  describe '#if_file_changed' do
    before do
      @digest = mock()
      @digest.stubs(:hexdigest).returns('abc')
      Digest::SHA256.stubs(:file).with('test_file').returns(@digest)
    end

    context 'called when no previous digest exists' do
      it 'executes the block' do
        @app.if_file_changed 'test_file', &block_should_execute
      end
    end

    context 'when an existing digest exists' do
      before do
        @app.if_file_changed 'test_file', &block_should_execute
      end

      it 'should not execute the block' do
        @app.if_file_changed 'test_file', &block_should_not_execute
      end

      context 'that is different' do
        before do
          @digest.unstub(:hexdigest)
          @digest.stubs(:hexdigest).returns('xyz')
        end

        it 'should execute the block' do
          @app.if_file_changed 'test_file', &block_should_execute
        end
      end
    end
  end

  describe '#if_string_changed' do
    it 'runs the block when there is no previous value' do
      block = lambda {}
      block.expects(:call).once
      @app.if_string_changed('new_value', 'new_key', &block)
    end
  end

  describe '#system_exit_on_error' do
    context 'with failing command' do
      before do
        @app.stubs('exit')
        @app.stubs('system_command')
        @app.stubs('output')
        @last_process = mock()
        @last_process.stubs(:success?).returns(false)
        @last_process.stubs(:exitstatus).returns(1)
        @app.stubs('last_process').returns(@last_process)
      end

      it 'calls exit' do
        @app.unstub('exit')
        lambda { @app.system_exit_on_error('failing command') }.should raise_error SystemExit
      end

      it 'calls exit with the same status code as the system command' do
        @app.unstub('exit')
        @app.expects('exit').with(@last_process.exitstatus)
        @app.system_exit_on_error('failing command')
      end

      it 'prints out the output' do
        message = 'failing output'
        @app.stubs('system_command').returns(message)
        @app.expects('output').with(message)
        @app.system_exit_on_error('failing command')
      end

      it 'prints out a custom message' do
        message = 'failing output'
        new_message = 'different failing message'
        @app.stubs('system_command').returns(message)
        @app.expects('output').with(new_message)
        @app.system_exit_on_error('failing command', :failure_message => new_message)
      end

      it 'calls the failure callback' do
        block_called = false
        @app.system_exit_on_error('failing command', :on_failure => lambda { |a, b| block_called = true })
        block_called.should == true
      end

      it 'does not call the success callback' do
        block_called = false
        @app.system_exit_on_error('failing command', :on_success => lambda { |a, b| block_called = true })
        block_called.should == false
      end
    end

    context 'with successful command' do
      before do
        @app.stubs('system_command')
        @app.stubs('output')
        @last_process = mock()
        @last_process.stubs(:success?).returns(true)
      end

      it 'does not exit' do
        @app.system_exit_on_error('successful command')
      end

      it 'does not output anything' do
        @app.stubs('output').returns(lambda { fail })
        @app.system_exit_on_error('successful command', :failure_message => 'failure message')
      end

      it 'does not call the failure callback' do
        block_called = false
        @app.system_exit_on_error('successful command', :on_failure => lambda { |a, b| blocked_called = true })
        block_called.should == false
      end

      it 'does call the success callback' do
        block_called = false
        @app.system_exit_on_error('successful command', :on_success => lambda { |a, b| block_called = true })
        block_called.should == true
      end
    end
  end

  describe '#system_command' do
    it 'executes the command' do
      @app.system_command('echo "hi"').should match(/hi/)
    end

    it 'does not execute rm -rf - dedicated to swamy g' do
      lambda { @app.system_command('rm -rf') }.should raise_error
    end
  end

  describe '#string_keys' do
    it 'converts the symbol based hash to string' do
      @app.string_keys({:one => 1, :two => 2, 'three' => 3}).should == {'one' => 1, 'two' => 2, 'three' => 3}
    end
    it 'does not modify the string based hash' do
      @app.string_keys({'a' => 1, 'b' => 2, 'c' => 3}).should == {'a' => 1, 'b' => 2, 'c' => 3}
    end
  end

end