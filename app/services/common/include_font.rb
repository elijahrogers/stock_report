module Common
  module IncludeFont
    def add_font_code_light
      font_families.update( 'Code_Light' =>
      {
        normal: "#{Rails.root}/public/fonts/code_light_font/CODE-Light.ttf",
      }
      )
    end
    def add_font_awesome
      font_families.update( 'fa' =>
      {
        normal: "#{Rails.root}/public/fonts/fontawesome-webfont.ttf",
      }
      )
    end
  end
end
