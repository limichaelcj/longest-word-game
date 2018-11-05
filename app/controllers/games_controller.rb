require 'json'
require 'open-uri'

class GamesController < ApplicationController
  ALPHABET = ('A'..'Z').to_a
  VOWELS = %w(A E I O U)
  CONSONANTS = ALPHABET.reject { |letter| VOWELS.include? letter }
  COUNT = 7
  URL = "https://wagon-dictionary.herokuapp.com/"

  def new
    @letters = []
    COUNT.times do
      @letters << CONSONANTS.sample
    end
    rand(2..(COUNT / 2)).times do
      @letters[rand(1...COUNT)] = VOWELS.sample
    end
    @time_start = Time.now.to_f
  end

  def score
    @time_elapsed = Time.now.to_f - params[:time_start].to_f
    @word = params[:word]
    @answer = @word.upcase.split('')
    @letters = params[:letters].split('')
    @histogram = {}
    @letters.each { |letter| @histogram[letter] ? @histogram[letter] += 1 : @histogram[letter] = 1 }
    @valid = @answer.all? do |letter|
      answer_count = @answer.select { |l| l == letter }.count
      @histogram[letter] && answer_count <= @histogram[letter]
    end
    if @valid
      endpoint = URL + @word
      data = JSON.parse(open(endpoint).read)
      if data['found']
        vowel_count = @answer.select { |l| VOWELS.include? l }.count
        vowel_multiplier = COUNT.fdiv(vowel_count).fdiv(2)
        time_multiplier = 6.fdiv(@time_elapsed)
        base_score = data['length'].fdiv(COUNT) * 10
        bonus_score = base_score * vowel_multiplier * time_multiplier
        @score = bonus_score.round(2)
        @message = "Answered with '#{@word}' in #{@time_elapsed.round(2)} seconds"
      else
        @score = 0
        @message = "That's not a real word!"
      end
    else
      @score = 0
      @message = "You must use the given letters!"
    end
  end
end
