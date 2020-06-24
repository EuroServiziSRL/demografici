class Indirizzo
  @indirizzo = {}

  def initialize(indirizzoHash) 
    puts "creating indirizzo with #{indirizzoHash}" 
    @indirizzo = indirizzoHash  
  end  

  def indirizzo
    puts "called indirizzo, indirizzo is #{@indirizzo}" 
    return @indirizzo["indirizzo"]
  end

  def comune
    puts "called comune, indirizzo is #{@indirizzo}" 
    return @indirizzo["comune"]
  end

  def to_s
    puts "called to_s, indirizzo is #{@indirizzo}" 
    return @indirizzo["indirizzo"]
  end
end
