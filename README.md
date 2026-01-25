# Development Lifecycle

## Setup - Testing Console

- make sure that `bin/build` has execution permissions:
`chmod +x bin/build`

- build the gem, starting up a irb instance requiring it:
`bin/build`

## Handling Interactive Replies

Process button clicks and list selections from WhatsApp interactive messages:

```ruby
ZapMessage.configure do |config|
  config.on(:message_received) do |event|
    if event.interactive_reply?
      case event.interactive_type
      when 'button_reply'
        handle_button(event.button_reply_id, event.button_reply_title)
      when 'list_reply'
        handle_list_selection(event.list_reply_id, event.list_reply_title)
      end
    end
  end
end
```
