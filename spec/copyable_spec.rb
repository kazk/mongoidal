require 'spec_helper'

class CopyableChild
  include Mongoid::Document
  field :label

  embedded_in :copyable_example
end

class CopyableExample
  include Mongoid::Document
  include Mongoidal::Copyable

  field :name, type: String
  field :address, type: String

  embeds_many :copyable_childs
end

describe Mongoidal::Copyable do
  let(:a) { CopyableExample.new(name: 'name', address: 'address') }
  let(:b) { CopyableExample.new }
  let(:a_child) { a.copyable_childs.build(label: 'a') }
  let(:b_child) { b.copyable_childs.first }

  describe '#copy_changes_to' do
    before do
      a.name = '1'
      a.address = '2'
    end

    it 'should copy specific fields' do
      a.copy_changes_to(b, :name)
      expect(b.name).to eq '1'
      expect(b.address).to be_nil
    end

    it 'should copy all fields' do
      a.copy_changes_to(b)
      expect(b.name).to eq '1'
      expect(b.address).to eq '2'
    end
  end

  describe '#copy_to' do
    before { a_child.save }
    before { a.copy_to(b) }

    it 'should copy fields' do
      b.save
      b.reload
      expect(b.name).to eq a.name
      expect(b.address).to eq a.address
      expect(b_child.label).to eq 'a'
      expect(b_child.id).not_to eq a_child.id
    end

    it 'should not copy id' do
      expect(b.id).not_to eq a.id
    end
  end

  describe '#copy_fields_to' do
    context 'when no existing values' do
      before do
        a_child.save
        a.copy_fields_to(b, :address, :copyable_childs)
        b.save
        b.reload
      end

      it 'should copy fields' do
        expect(b.address).to eq a.address
        expect(b_child.label).to eq 'a'
      end

      it 'should reset ids' do
        expect(b_child.id.to_s).to_not eq a_child.id.to_s
      end
    end

    context 'when values exist' do
      let(:b) { CopyableExample.new(address: '1') }

      describe 'overwrite_nil_only' do
        before do
          a_child.save
          a.copy_fields_to(b, :address, :copyable_childs, overwrite_nil_only: true)
          b.save
          b.reload
        end

        it 'should support overwrite_nil_only' do
          expect(b.address).to eq '1'
          expect(b_child.label).to eq 'a'
        end

      end

      describe 'ignore_nil_source' do
        context 'when true' do
          before do
            a.address = nil
            b.address = 'test'
            a.copy_fields_to(b, :address)
            b.save
            b.reload
          end

          it 'should not have replaced address' do
            expect(b.address).to eq 'test'
          end
        end

        context 'when false' do
          before do
            a.address = nil
            b.address = 'test'
            a.copy_fields_to(b, :address, ignore_nil_source: false)
            b.save
            b.reload
          end

          it 'should not have replaced address' do
            expect(b.address).to be_nil
          end
        end
      end
    end
  end
end