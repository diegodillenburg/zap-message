# frozen_string_literal: true

require_relative 'spec_helper'
require_relative '../lib/zap_message'

RSpec.describe ZapMessage::PhoneFormatter do
  describe '.format' do
    context 'with valid phone numbers' do
      it 'formats Brazilian phone number' do
        result = described_class.format('+55 11 99999-9999')

        expect(result).to eq('5511999999999')
      end

      it 'formats US phone number' do
        result = described_class.format('+1 (555) 123-4567')

        expect(result).to eq('15551234567')
      end

      it 'returns already formatted number unchanged' do
        result = described_class.format('5511999999999')

        expect(result).to eq('5511999999999')
      end

      it 'handles phone with spaces and dashes' do
        result = described_class.format('55-11-99999-9999')

        expect(result).to eq('5511999999999')
      end

      it 'handles phone with parentheses' do
        result = described_class.format('55(11)999999999')

        expect(result).to eq('5511999999999')
      end
    end

    context 'with invalid phone numbers' do
      it 'raises error for too long number' do
        expect do
          described_class.format('1234567890123456')
        end.to raise_error(ZapMessage::Error::InvalidPhoneNumber)
      end

      it 'cleans and formats number with letters' do
        result = described_class.format('55abc11999999999')

        expect(result).to eq('5511999999999')
      end

      it 'returns empty string for nil' do
        expect(described_class.format(nil)).to be_nil
      end

      it 'returns empty string for empty string' do
        expect(described_class.format('')).to eq('')
      end
    end
  end

  describe '.valid?' do
    context 'with valid numbers' do
      it 'validates Brazilian phone' do
        expect(described_class.valid?('5511999999999')).to be true
      end

      it 'validates US phone' do
        expect(described_class.valid?('15551234567')).to be true
      end

      it 'validates formatted phone' do
        expect(described_class.valid?('+55 11 99999-9999')).to be true
      end

      it 'validates short number' do
        expect(described_class.valid?('123')).to be true
      end
    end

    context 'with invalid numbers' do
      it 'returns false for too long number' do
        expect(described_class.valid?('1234567890123456')).to be false
      end

      it 'returns false for empty string' do
        expect(described_class.valid?('')).to be false
      end

      it 'returns false for nil' do
        expect(described_class.valid?(nil)).to be false
      end

      it 'validates number with letters after cleaning' do
        expect(described_class.valid?('55abc11')).to be true
      end
    end
  end

  describe '.parse' do
    context 'with valid phone numbers' do
      it 'parses Brazilian phone number' do
        result = described_class.parse('5511999999999')

        expect(result[:country_code]).to eq('55')
        expect(result[:area_code]).to eq('11')
        expect(result[:number]).to eq('999999999')
      end

      it 'parses US phone number' do
        result = described_class.parse('+1 555 123-4567')

        expect(result[:country_code]).to eq('15')
        expect(result[:area_code]).to eq('55')
        expect(result[:number]).to eq('1234567')
      end

      it 'parses formatted phone' do
        result = described_class.parse('+55 (11) 99999-9999')

        expect(result[:country_code]).to eq('55')
        expect(result[:area_code]).to eq('11')
        expect(result[:number]).to eq('999999999')
      end
    end

    context 'with invalid phone numbers' do
      it 'returns empty hash for too short number' do
        result = described_class.parse('12')

        expect(result).to eq({})
      end

      it 'returns empty hash for invalid number' do
        result = described_class.parse('abc')

        expect(result).to eq({})
      end

      it 'returns empty hash for nil' do
        result = described_class.parse(nil)

        expect(result).to eq({})
      end

      it 'returns empty hash for empty string' do
        result = described_class.parse('')

        expect(result).to eq({})
      end
    end
  end
end
