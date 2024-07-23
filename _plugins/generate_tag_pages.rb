module Jekyll
  class TagPage < Page
    def initialize(site, base, dir, tag)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag_page.html')
      self.data['tag'] = tag
      self.data['title'] = "Posts tagged with '#{tag}'"
    end
  end

  class TagGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'tag_page'
        dir = 'tags'
        site.tags.each_key do |tag|
          write_tag_page(site, File.join(dir, tag.gsub(/\s+/, '-').downcase), tag)
        end
      end
    end

    def write_tag_page(site, dir, tag)
      index = TagPage.new(site, site.source, dir, tag)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.pages << index
    end
  end
end
