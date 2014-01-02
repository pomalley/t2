module ApplicationHelper

    def full_title(page_title)
        base_title = "T2"
        if page_title.empty?
            base_title
        else
            "#{base_title} | #{page_title}"
        end
    end
    
    def markdown(text)
        text ||= ""
        renderer = Redcarpet::Render::HTML.new(
            filter_html: true, hard_wrap: true)
        markdown = Redcarpet::Markdown.new(renderer,
            autolink: true, no_intra_emphasis: true, fenced_code_blocks: true)
        markdown.render(text).html_safe
    end

end
