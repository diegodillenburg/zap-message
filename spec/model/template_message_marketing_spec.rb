# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/zap_message'

RSpec.describe ZapMessage::Model::TemplateMessage, '#marketing_attributes' do
  def template(**options)
    described_class.new(to: '5511999999999', name: 'promo', language_code: 'pt_BR', **options)
  end

  it 'equals #attributes when no marketing options are set' do
    message = template

    expect(message.marketing_attributes).to eq(message.attributes)
  end

  it 'adds product_policy' do
    expect(template(product_policy: 'CLOUD_API_FALLBACK').marketing_attributes)
      .to include(product_policy: 'CLOUD_API_FALLBACK')
  end

  it 'keeps message_activity_sharing: false' do
    expect(template(message_activity_sharing: false).marketing_attributes)
      .to include(message_activity_sharing: false)
  end

  it 'keeps the options out of #attributes' do
    attributes = template(product_policy: 'STRICT', message_activity_sharing: true).attributes

    expect(attributes).not_to have_key(:product_policy)
    expect(attributes).not_to have_key(:message_activity_sharing)
  end

  it 'rejects an unknown product_policy' do
    expect { template(product_policy: 'strict').marketing_attributes }
      .to raise_error(ZapMessage::Error::ValidationFailure, /product_policy/)
  end

  it 'rejects a non-boolean message_activity_sharing' do
    expect { template(message_activity_sharing: 'yes').marketing_attributes }
      .to raise_error(ZapMessage::Error::ValidationFailure, /message_activity_sharing/)
  end
end
