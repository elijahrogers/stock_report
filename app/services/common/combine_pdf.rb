module Common
  module CombinePdf
    def to_pdf
      init_pdf
      combinded_pdf = CombinePDF.new
      CombinePDF.parse(render).pages.size.times do
        combinded_pdf << CombinePDF.load(@template)
      end
      combinded_pdf.pages.each_with_index do |page, indx|
        page << CombinePDF.parse(render).pages[indx]
      end
      combinded_pdf.to_pdf
    end
  end
end
