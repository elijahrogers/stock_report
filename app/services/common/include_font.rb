module Common
  module IncludeFont
    def add_font_code_light
      font_families.update( 'Code_Light' =>
      {
        normal: "#{Rails.root}/public/fonts/code_light_font/CODE-Light.ttf",
      }
      )
    end
  end
end
