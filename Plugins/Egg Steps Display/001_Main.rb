module EggStepsDisplay
  module_function

  def get_remaining_steps(pokemon)
    return 0 unless pokemon.egg?
    remaining = [pokemon.steps_to_hatch.to_i, 0].max
    faster = $player&.pokemon_party&.any? do |pkmn|
      pkmn.ability&.has_flag?("FasterEggHatching")
    end
    faster ? (remaining + 1) / 2 : remaining
  end

  def get_total_steps(pokemon)
    pokemon.egg? ? pokemon.species_data.hatch_steps : 0
  end

  def get_progress_percentage(pokemon)
    total = get_total_steps(pokemon)
    return 0 if total <= 0
    remaining = [pokemon.steps_to_hatch.to_i, 0].max
    [[((total - remaining) * 100.0 / total).round, 0].max, 100].min
  end

  def format_steps_text(pokemon)
    return "" unless pokemon.egg?
    remaining = get_remaining_steps(pokemon)
    return _INTL("Ready to hatch!") if remaining == 0
    return _INTL("1 step remaining") if remaining == 1
    _INTL("{1} steps remaining", remaining)
  end

  def get_steps_color(pokemon)
    remaining = get_remaining_steps(pokemon)
    return COLOR_READY if remaining == 0
    return COLOR_CLOSE if remaining <= CLOSE_THRESHOLD
    return COLOR_MEDIUM if remaining <= MEDIUM_THRESHOLD
    COLOR_FAR
  end

  def draw_progress_bar(bitmap, x, y, width, height, pokemon)
    return unless SHOW_PROGRESS_BAR && pokemon.egg? && width > 2 && height > 2
    bitmap.fill_rect(x, y, width, height, Color.new(0, 0, 0))
    bitmap.fill_rect(x + 1, y + 1, width - 2, height - 2, PROGRESS_BAR_EMPTY)
    filled = ((width - 2) * get_progress_percentage(pokemon) / 100.0).round
    color = get_remaining_steps(pokemon) <= CLOSE_THRESHOLD ? PROGRESS_BAR_ALMOST : PROGRESS_BAR_FULL
    bitmap.fill_rect(x + 1, y + 1, filled, height - 2, color) if filled > 0
  end
end

class EggStepsOverlay
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @background = Sprite.new(@viewport)
    @background.bitmap = Bitmap.new(EggStepsDisplay::OVERLAY_WIDTH, EggStepsDisplay::OVERLAY_HEIGHT)
    @background.bitmap.fill_rect(0, 0, EggStepsDisplay::OVERLAY_WIDTH,
                                 EggStepsDisplay::OVERLAY_HEIGHT,
                                 Color.new(0, 0, 0, EggStepsDisplay::OVERLAY_BACKGROUND_OPACITY))
    @background.x = Graphics.width - EggStepsDisplay::OVERLAY_WIDTH - EggStepsDisplay::OVERLAY_X_OFFSET
    @background.y = EggStepsDisplay::OVERLAY_Y_OFFSET
    @text = Sprite.new(@viewport)
    @text.bitmap = Bitmap.new(EggStepsDisplay::OVERLAY_WIDTH - 16, EggStepsDisplay::OVERLAY_HEIGHT - 12)
    @text.x = @background.x + 8
    @text.y = @background.y + 6
    refresh
  end

  def refresh
    egg = $player&.party&.find(&:egg?)
    @background.visible = @text.visible = !!egg
    return unless egg
    bitmap = @text.bitmap
    bitmap.clear
    bitmap.font.size = EggStepsDisplay::FONT_SIZE_OVERLAY
    bitmap.font.color = EggStepsDisplay.get_steps_color(egg)
    bitmap.draw_text(0, 0, bitmap.width, 25, EggStepsDisplay.format_steps_text(egg), 1)
    EggStepsDisplay.draw_progress_bar(bitmap, 8, 30, bitmap.width - 16, 7, egg)
  end

  def dispose
    [@background, @text].each do |sprite|
      sprite.bitmap.dispose if sprite.bitmap && !sprite.bitmap.disposed?
      sprite.dispose unless sprite.disposed?
    end
    @viewport.dispose unless @viewport.disposed?
  end
end

EventHandlers.add(:on_game_map_setup, :egg_steps_overlay_setup, proc { |_map_id|
  if EggStepsDisplay::SHOW_LIVE_OVERLAY
    $egg_steps_overlay ||= EggStepsOverlay.new
    $egg_steps_overlay.refresh
  end
})

EventHandlers.add(:on_player_step_taken, :egg_steps_overlay_update, proc {
  $egg_steps_overlay.refresh if $egg_steps_overlay
})

class Scene_Map
  alias egg_steps_display_dispose dispose
  def dispose
    $egg_steps_overlay&.dispose
    $egg_steps_overlay = nil
    egg_steps_display_dispose
  end
end
