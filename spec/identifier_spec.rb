# frozen_string_literal: true

require_relative 'spec_helper'
require_relative '../lib/zap_message'

RSpec.describe ZapMessage::Identifier do
  describe '.bsuid?' do
    it 'recognizes a regular BSUID' do
      expect(described_class.bsuid?('US.13491208655302741918')).to be true
    end

    it 'recognizes a parent BSUID' do
      expect(described_class.bsuid?('US.ENT.11815799212886844830')).to be true
    end

    it 'recognizes alphanumeric BSUIDs' do
      expect(described_class.bsuid?('BR.1A2B3C4D5E6F7G8H9I0J')).to be true
    end

    it 'rejects a plain phone number' do
      expect(described_class.bsuid?('5511999999999')).to be false
    end

    it 'rejects a formatted phone number' do
      expect(described_class.bsuid?('+55 11 99999-9999')).to be false
    end

    it 'rejects lowercase country codes' do
      expect(described_class.bsuid?('us.13491208655302741918')).to be false
    end

    it 'rejects nil and empty' do
      expect(described_class.bsuid?(nil)).to be false
      expect(described_class.bsuid?('')).to be false
    end
  end

  describe '.parent_bsuid?' do
    it 'is true for a parent BSUID' do
      expect(described_class.parent_bsuid?('US.ENT.11815799212886844830')).to be true
    end

    it 'is false for a regular BSUID' do
      expect(described_class.parent_bsuid?('US.13491208655302741918')).to be false
    end
  end

  describe '.type' do
    it 'returns :bsuid for a BSUID' do
      expect(described_class.type('US.13491208655302741918')).to eq(:bsuid)
    end

    it 'returns :phone for a phone number' do
      expect(described_class.type('5511999999999')).to eq(:phone)
    end
  end

  describe '.normalize' do
    it 'passes a BSUID through verbatim' do
      bsuid = 'US.13491208655302741918'
      expect(described_class.normalize(bsuid)).to eq(bsuid)
    end

    it 'passes a parent BSUID through verbatim' do
      bsuid = 'US.ENT.11815799212886844830'
      expect(described_class.normalize(bsuid)).to eq(bsuid)
    end

    it 'formats a phone number to E.164 digits' do
      expect(described_class.normalize('+55 11 99999-9999')).to eq('5511999999999')
    end

    it 'returns nil/empty unchanged' do
      expect(described_class.normalize(nil)).to be_nil
      expect(described_class.normalize('')).to eq('')
    end

    it 'raises for an invalid phone number (not a BSUID)' do
      expect do
        described_class.normalize('1234567890123456')
      end.to raise_error(ZapMessage::Error::InvalidPhoneNumber)
    end
  end
end
