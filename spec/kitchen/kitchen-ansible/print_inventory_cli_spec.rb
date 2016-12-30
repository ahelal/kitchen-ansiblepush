require_relative '../../spec_helper'

require 'kitchen-ansible/print_inventory_cli'


describe PrintInventory do
  before :each do
    @printinventory = PrintInventory.new
  end

  describe '#new' do
    it 'Returns PrintInventory' do
      @printinventory.should be_an_instance_of PrintInventory
    end
  end

end
