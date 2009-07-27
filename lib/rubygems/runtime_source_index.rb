module Gem
  class RuntimePath
    def self.from_gems_in(path)
      index = new(path)
    end
    
    def initialize(path)
      @index, @path = {}, Pathname.new(path).join("specifications")
    end
    
    def find_name(name, requirements)
      
    end
    
    def search(dependency)
      self[dependency.name].select {|m| m.satisfies_requirement?(dependency) }
    end
    
    private
    def [](name)
      @index[name] ||= begin
        matches = []
        
        if File.directory?(@path.join(name))
          Dir[@path.join(name, "*.gemspec")].each do |file|
            matches << eval(File.read(file))
          end
        end
        matches
      end
    end
  end
  
  class RuntimeSourceIndex
    def self.from_installed_gems
      from_gems_in *Gem.path.map {|path| File.join(path, "specifications") }
    end
    
    def self.from_gems_in(*dirs)
      new(*dirs)
    end

    def initialize(*dirs)
      @indexes = dirs.map! {|dir| RuntimePath.new(dir) }
    end

    def find_name(name, requirements)
      results = []
      @indexes.each do |index|
        results.concat index.find_name(name, requirements)
      end
      results
    end

    def search(gem_dependency)
      results = []
      @indexes.each do |index|
        results.concat index.search(gem_dependency)
      end
      results
    end
  end
end