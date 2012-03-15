require 'spec_helper'

describe Rockit::Cli do
  before do
    Kernel.stubs('exec')
    Rockit::Application.any_instance.stubs('run')
  end
  describe '.start' do
    context 'with no arguments' do
      it 'calls the application run' do
        Rockit::Application.any_instance.expects('run')
        Rockit::Cli.start
      end
    end

    context 'with the -f flag' do
      it 'calls clears the cache' do
        Rockit::Application.any_instance.expects('clear_cache')
        Rockit::Cli.start(['-f'])
      end
    end

    context 'with additional arguments' do
      it 'clears the cache' do
        args = ['rails', 'server']
        Kernel.expects('exec').with(*args)
        Rockit::Cli.start(args)
      end
    end

  end

end