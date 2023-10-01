class TextToSpeechJob < ApplicationJob
  queue_as :default

  def perform(prompt)
    prompt_with_instruction = "The following is a question that requires a single answer:\n#{prompt}\n"

    gpt_response = send_prompt_to_openai(prompt_with_instruction)
    gpt_text = parse_gpt_response(gpt_response)

    return unless gpt_text

    audio_response = send_text_to_speech_request(gpt_text)

    create_audio_file(audio_response, prompt)
  end

  def send_prompt_to_openai(prompt_with_instruction)
    Faraday.post('https://api.openai.com/v1/chat/completions') do |req|
      req.headers['Authorization'] = "Bearer #{Rails.application.credentials.open_api_key}"
      req.headers['Content-Type'] = 'application/json'
      req.body = body_for_gpt(prompt_with_instruction)
    end
  end

  def body_for_gpt(prompt_with_instruction)
    {
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'user',
          content: prompt_with_instruction
        }
      ],
      # Tokens = words
      max_tokens: 50,
      temperature: 0.1,
      top_p: 1,
      frequency_penalty: 0,
      presence_penalty: 0,
    }.to_json
  end

  def parse_gpt_response(gpt_response)
    if gpt_response.status == 200
      JSON.parse(gpt_response.body)['choices'].first['message']['content']
    else
      puts "Error: #{gpt_response.status} - #{gpt_response.body}"
      nil
    end
  end

  def send_text_to_speech_request(gpt_text)
    # Do something later
    Faraday.post('https://api.elevenlabs.io/v1/text-to-speech/tFNDLLYIRNYLCP4H25ro') do |req|
      req.headers['accept'] = 'audio/mpeg'
      req.headers['xi-api-key'] = Rails.application.credentials.xi_api_key
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        text: gpt_text,
        model_id: 'eleven_monolingual_v1',
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.5
        }
      }.to_json
    end
  end

  def create_audio_file(response, prompt)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(response.body),
      filename: 'audio.mp3',
      content_type: 'audio/mpeg'
    )

    Audio.create!(prompt:, file: blob)
  end
end
