module BackgrounDRb
  class ResultStorage
    attr_accessor :cache,:worker_name,:worker_key
    def initialize(worker_name,worker_key,storage_type = nil)
      @worker_name = worker_name
      @worker_key = worker_key
      @mutex = Mutex.new
      @storage_type = storage_type
      @cache = (@storage_type == :memcache) ? memcache_instance : {}
    end

    def memcache_instance
      require 'memcache'
      memcache_options = {
        :c_threshold => 10_000,
        :compression => true,
        :debug => false,
        :namespace => 'backgroundrb_result_hash',
        :readonly => false,
        :urlencode => false
      }
      t_cache = MemCache.new(memcache_options)
      t_cache.servers = CONFIG_FILE[:memcache].split(',')
      t_cache
    end

    def gen_key key
      if storage_type == :memcache
        [woker_name,worker_key,key].compact.join('_')
      else
        key
      end
    end

    def [] key
      @mutex.synchronize { @cache[gen_key(key)] }
    end

    def []= key,value
      @mutex.synchronize { @cache[gen_key(key)] = value }
    end

    def delete key
      @mutex.synchronize { @cache.delete(gen_key(key)) }
    end

    def shift key
      val = nil
      @mutex.synchronize do
        val = @cache[key]
        @cache.delete(key)
      end
      return val
    end
  end
end

