require 'spec_helper'

describe Rocketstrap::Cli do
  before do
    Kernel.stubs('exec')
    Rocketstrap::Application.any_instance.stubs('run')
  end
  describe '.start' do
    context 'with no arguments' do
      it 'calls the application run' do
        Rocketstrap::Application.any_instance.expects('run')
        Rocketstrap::Cli.start
      end
    end

    context 'with the -f flag' do
      it 'calls clears the cache' do
        Rocketstrap::Application.any_instance.expects('clear_cache')
        Rocketstrap::Cli.start(['-f'])
      end
    end

    context 'with additional arguments' do
      it 'clears the cache' do
        args = ['rails', 'server']
        Kernel.expects('exec').with(*args)
        Rocketstrap::Cli.start(args)
      end
    end

  end

end