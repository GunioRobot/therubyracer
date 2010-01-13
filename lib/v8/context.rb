module V8
  class Context    
    def initialize(opts = {})      
      @native = C::Context.new(opts[:with])
    end
    
    def open(&block)
      @native.open do
        block.call(self)
      end if block_given?
    end
    
    def eval(javascript, sourcename = '<eval>', line = 1)
      if IO === javascript || StringIO === javascript
        javascript = javascript.read()
      end
      @native.eval(javascript).tap do |result|
        raise JavascriptError.new(result) if result.kind_of?(C::Message)
        return To.ruby(result)
      end
    end
        
    def evaluate(*args)
      self.eval(*args)
    end
    
    def load(filename)
      File.open(filename) do |file|
        evaluate file, filename, 1
      end      
    end
    
    def [](key)
      ContextError.check_open('V8::Context#[]')
      To.ruby(@native.Global().Get(key.to_s))
    end
    
    def []=(key, value)
      ContextError.check_open('V8::Context#[]=')
      value.tap do 
        @native.Global().tap do |scope|
          scope.Set(key.to_s, value)
        end
      end
    end
    
    def self.open(opts = {}, &block)
      new(opts).open(&block)
    end    
  end
  
  class ContextError < StandardError
    def initialize(caller_name)
      super("tried to call method '#{caller_name} without an open context")
    end
    def self.check_open(caller_name)
      raise new(caller_name) unless C::Context::InContext()
    end
  end
  class JavascriptError < StandardError
    def initialize(v8_message)
      super(v8_message.Get())
    end
  end
  class RunawayScriptError < ContextError
  end
end