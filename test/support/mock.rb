# Reference from https://github.com/seattlerb/minitest/blob/master/lib/minitest/mock.rb#L207
class Object
  ##
  # Add a temporary stubbed method replacing +name+ for the duration
  # of the +block+. If +val_or_callable+ responds to #call, then it
  # returns the result of calling it, otherwise returns the value
  # as-is. If stubbed method yields a block, +block_args+ will be
  # passed along. Cleans up the stub at the end of the +block+. The
  # method +name+ must exist before stubbing.
  #
  #     def test_stale_eh
  #       obj_under_test = Something.new
  #       refute obj_under_test.stale?
  #
  #       Time.stub :now, Time.at(0) do
  #         assert obj_under_test.stale?
  #       end
  #     end
  #

  def stub name, val_or_callable, *block_args
    new_name = "__minitest_stub__#{name}"

    metaclass = class << self; self; end

    if respond_to? name and not methods.map(&:to_s).include? name.to_s then
      metaclass.send :define_method, name do |*args|
        super(*args)
      end
    end

    metaclass.send :alias_method, new_name, name

    metaclass.send :define_method, name do |*args, &blk|
      if val_or_callable.respond_to? :call then
        val_or_callable.call(*args, &blk)
      else
        blk.call(*block_args) if blk
        val_or_callable
      end
    end

    yield self
  ensure
    metaclass.send :undef_method, name
    metaclass.send :alias_method, name, new_name
    metaclass.send :undef_method, new_name
  end
end
