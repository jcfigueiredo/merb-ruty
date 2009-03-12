# To change this template, choose Tools | Templates
# and open the template in the editor.

class UserFixture
  
  attr_accessor :first_name, :last_name, :age, :children

  def initialize(first_name, age, last_name = '')
    @first_name, @last_name, @age = first_name, last_name, age

    @children =  Array.new
  end

  def get_children
    @children.insert(UserFixture.new('one', 1))
    @children.insert(UserFixture.new('two', 2))
    return @children
  end

  def full_name
    return "%s %s" %[first_name, last_name]
  end

  def full_unsafe_name
    return full_name
  end

  def ruty_safe?(name)
    [:full_name].include?(name)
  end
end

