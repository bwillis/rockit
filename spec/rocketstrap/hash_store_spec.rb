require 'spec_helper'

describe Rocketstrap::HashStore do

  before do
    @hash_store = Rocketstrap::HashStore.new
  end


  context '#filepath' do
    it 'creates the hash store file' do
      File.exists?(@hash_store.send(:filepath)).should == true
    end
  end

  context '#get/#set' do
    before do

    end
    context 'when getting an unsaved key' do
      it 'returns nil' do
        @hash_store['unsaved_key'].should be_nil
      end
    end

    context 'when setting a new key' do
      before do
        @hash_store['saved_key'] = 'value'
        @hash_store['saved_key_2'] = 'value2'
      end
      it 'can retrieve the saved value' do
        @hash_store['saved_key'].should == 'value'
      end
    end

    context 'when setting an existing key' do
      before do
        @hash_store['saved_key_1'] = 'value_1'
        @hash_store['saved_key_1'] = 'value_2'
      end
      it 'can retrieve the latest saved value' do
        @hash_store['saved_key_1'].should == 'value_2'
      end
    end
  end

  after do
    @hash_store.destroy
  end
end