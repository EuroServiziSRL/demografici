class AutocertDateTime
  @dateTime = DateTime.now
  class << self
    def parse(format)
      @dateTime = DateTime.parse(format);
      return self;
    end

    def to_date   
      @dateTime = @dateTime.to_date;
      return self;   
    end
  
    def lformat(format = :default, locale=nil, options={})
      return @dateTime.strftime("%d/%m/%Y")
    end
  end
end
