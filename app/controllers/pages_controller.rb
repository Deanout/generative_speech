class PagesController < ApplicationController
  def home
    @audios = Audio.all.order(created_at: :desc)
  end


  def tts
    TextToSpeechJob.perform_later(audio_params[:prompt])

    redirect_to root_path, notice: "Audio is being generated. Please wait a few minutes."
  end

  private

  def audio_params
    params.permit(:prompt)
  end
end
