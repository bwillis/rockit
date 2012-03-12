require 'spec_helper'

describe Rocketstrap::Application do
  before do
    @app = Rocketstrap::Application.new
  end

  describe '#if_checksum_changed' do
    context 'called when no previous checksum exists' do
      before do
        File.stubs('exists?').returns(false)
      end
    end

    context 'with a unchanged checksum' do
      before do
        File.stubs('exists?').returns(true)
        File.stubs('read').returns('abc')
        digest = mock()
        digest.stubs('hexdigest').returns('abc')
        Digest::SHA256.stubs('file').returns(digest)
      end

      it 'executes the block' do
        @app.if_checksum_changed('fake', 'fake_out') do
          fail
        end
      end
    end

    context 'with a changed checksum' do
      before do
        @new_checksum = 'xyz'
        File.stubs('exists?').returns(true)
        File.stubs('read').returns('abc')
        File.stubs('open').returns(true)
        digest = mock()
        digest.stubs('hexdigest').returns(@new_checksum)
        Digest::SHA256.stubs('file').returns(digest)
      end

      it 'executes the block' do
        block_executed = false
        @app.if_checksum_changed('fake', 'fake_out') do
          block_executed = true
        end
        block_executed.should == true
      end
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
        @app.system_exit_on_error('failing command', :failure_callback => lambda { |a, b| block_called = true })
        block_called.should == true
      end

      it 'does not call the success callback' do
        block_called = false
        @app.system_exit_on_error('failing command', :success_callback => lambda { |a, b| block_called = true })
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
        @app.system_exit_on_error('successful command', :failure_callback => lambda{|a,b| blocked_called = true})
        block_called.should == false
      end

      it 'does call the success callback' do
        block_called = false
        @app.system_exit_on_error('successful command', :success_callback => lambda{|a,b| block_called = true})
        block_called.should == true
      end
    end
  end

  describe '#run' do
    context 'when called a configuration file turns off rails dep' do
      before do
        File.stubs('exists?').with('Rocketfile').returns(true)
        File.stubs('read').with('Rocketfile').returns("rails_checks_off")
      end
      it 'does not call rails checks' do
        @app.stubs('rails_checks').returns(lambda{fail})
        @app.run
      end
    end

  end

end