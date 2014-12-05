class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  require 'diarize'
  respond_to :json

  SPEAKERS = []

  def register
    u = URI(params[:file])
    u.scheme = 'file'
    audio = Diarize::Audio.new u
    audio.analyze!
    speaker = audio.speakers.first
    speaker.save_model("audio_files/user_models/#{ params[:user_hash] }")
    puts SPEAKERS.count
    SPEAKERS << { speaker: speaker, user: params[:user_hash] }
    puts SPEAKERS.count
    render json: { message: 'User registered.' }, status: :ok
  end

  def log_in
    u = URI(params[:file])
    u.scheme = 'file'
    audio = Diarize::Audio.new u
    audio.analyze!
    model = audio.speakers.first
    pairs = []
    puts SPEAKERS.count
    SPEAKERS.each do |speaker|
      pairs << { divergence: Diarize::Speaker.divergence(model, speaker[:speaker]), speaker: speaker }
    end
    min = 4
    min_speaker = -1
    pairs.each do |pair|
      puts pair[:divergence]
      if min > pair[:divergence]
        min = pair[:divergence]
        min_speaker = pair[:speaker]
      end
    end
    puts min
    if min < 1.8
      min_speaker
      render json: { user_hash: min_speaker[:user] }, status: :ok
    else
      render json: { message: 'User not found.' }, status: :not_found
    end
  end

  private

  def get_file_name path
    path.split('/').last
  end
end
