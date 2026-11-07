if defined?(UI::PokemonSummaryVisuals) && defined?(UI::PartyVisualsPanel)

class UI::PokemonSummaryVisuals
  alias __egg_steps__draw_egg_memo draw_egg_memo unless method_defined?(:__egg_steps__draw_egg_memo)

  def draw_egg_memo
    if !EggStepsDisplay::SHOW_IN_SUMMARY
      __egg_steps__draw_egg_memo
      return
    end
    red_text_tag   = shadowc3tag(*get_text_color_theme(:shiny))
    black_text_tag = shadowc3tag(*get_text_color_theme(:black))
    memo = ""
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      if defined?(Translation) && Translation.month_day_date_format?
        memo += black_text_tag + _INTL("{1} {2}, {3}", month, date, year) + "\n"
      else
        memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
      end
    end
    map_name = pbGetMapNameFromId(@pokemon.obtain_map)
    map_name = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
    if map_name && map_name != ""
      map_name = red_text_tag + map_name + black_text_tag
      memo += black_text_tag + _INTL("A mysterious Pokémon Egg received from {1}.", map_name) + "\n"
    else
      memo += black_text_tag + _INTL("A mysterious Pokémon Egg.") + "\n"
    end
    draw_formatted_text(memo, 232, 86, 268)
    draw_text(_INTL("The Egg Watch"), 238, 246, theme: :white)
    remaining = EggStepsDisplay.get_remaining_steps(@pokemon)
    if remaining <= 0
      egg_state = _INTL("This Egg is ready to hatch!")
    elsif remaining == 1
      egg_state = _INTL("This Egg needs just 1 more step to hatch!")
    elsif remaining <= 100
      egg_state = _INTL("This Egg is very close to hatching! Only {1} steps remain.", remaining)
    elsif remaining <= 500
      egg_state = _INTL("This Egg is getting close to hatching. {1} steps remain.", remaining)
    else
      egg_state = _INTL("This Egg still needs {1} steps to hatch.", remaining)
    end
    draw_formatted_text(black_text_tag + egg_state, 232, 278, 268)
  end
end

def pbToggleEggStepsOverlay
  if $egg_steps_overlay
    $egg_steps_overlay.dispose
    $egg_steps_overlay = nil
    pbMessage(_INTL("Egg steps overlay hidden."))
  else
    $egg_steps_overlay = EggStepsOverlay.new
    pbMessage(_INTL("Egg steps overlay shown."))
  end
end

def pbShowEggStepsInfo
  if $player.party.any? { |p| p.egg? }
    text = []
    $player.party.each_with_index do |pokemon, i|
      if pokemon.egg?
        remaining = EggStepsDisplay.get_remaining_steps(pokemon)
        total = EggStepsDisplay.get_total_steps(pokemon)
        progress = EggStepsDisplay.get_progress_percentage(pokemon)
        text.push(_INTL("Slot {1}: {2} steps ({3}%)", i + 1, remaining, progress))
      end
    end
    pbMessage(text.join("\n"))
  else
    pbMessage(_INTL("No eggs in party."))
  end
end

module EggStepsPartyPanel
  def draw_annotation
    super
    return unless EggStepsDisplay::SHOW_IN_PARTY && @pokemon&.egg?
    return if @text && !@text.empty?
    draw_text(EggStepsDisplay.format_steps_text(@pokemon), 94, 62, theme: :white)
    EggStepsDisplay.draw_progress_bar(@sprites[:overlay].bitmap, 96, 84, 120, 6, @pokemon)
  end
end

UI::PartyVisualsPanel.prepend(EggStepsPartyPanel)

else
class PokemonPartyPanel
  alias egg_steps_display_draw_annotation draw_annotation
  def draw_annotation
    egg_steps_display_draw_annotation
    return unless EggStepsDisplay::SHOW_IN_PARTY && @pokemon.egg?
    return if @text && !@text.empty?
    bitmap = @overlaysprite.bitmap
    pbSetSmallFont(bitmap)
    pbDrawTextPositions(bitmap, [[EggStepsDisplay.format_steps_text(@pokemon), 96, 58,
                                  :left, EggStepsDisplay.get_steps_color(@pokemon),
                                  TEXT_SHADOW_COLOR]])
    pbSetSystemFont(bitmap)
    EggStepsDisplay.draw_progress_bar(bitmap, 96, 82,
                                      EggStepsDisplay::PARTY_PROGRESS_BAR_WIDTH,
                                      EggStepsDisplay::PARTY_PROGRESS_BAR_HEIGHT, @pokemon)
  end
end

class PokemonSummary_Scene
  alias egg_steps_display_draw_page_one_egg drawPageOneEgg
  def drawPageOneEgg
    egg_steps_display_draw_page_one_egg
    return unless EggStepsDisplay::SHOW_IN_SUMMARY
    overlay = @sprites["overlay"].bitmap
    overlay.fill_rect(228, 324, 272, 52, Color.new(0, 0, 0, 180))
    overlay.font.size = EggStepsDisplay::FONT_SIZE_SUMMARY
    overlay.font.color = EggStepsDisplay.get_steps_color(@pokemon)
    overlay.draw_text(236, 326, 256, 28, EggStepsDisplay.format_steps_text(@pokemon), 0)
    EggStepsDisplay.draw_progress_bar(overlay, 236, 357, 256, 8, @pokemon)
  end
end

end
