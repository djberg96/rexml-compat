require 'nokogiri'

# Add class methods to nokogiri to have it behave more like REXML for easy replacement
module Nokogiri
  module XML
    class Attr
      # REXML::Attributes are typically accessed so that it returns the value of an
      # attribute, whereas Nokogiri returns an object with a "value" reader method.
      # Our approach essentially forwards the call to the value.
      #
      def method_missing(*args, &block)
        self.value.send(*args, &block)
      end
    end

    # Because an XML::Element is a subclass of XML::Node, we define methods on
    # the Node class and let them be inherited by the Element class.
    #
    class Node
      # Duplicates the REXML::Element#add_attribute method.
      def add_attribute(key, value)
        self[key.to_s] = value.to_s unless value.nil?
      end

      # Duplicates the REXML::Element#add_attributes method.
      def add_attributes(attr_hash)
        return unless attr_hash
        attr_hash.each_pair{ |k,v| self.add_attribute(k, v) }
      end

      # Duplicates the REXML::Element#add_element method.
      def add_element(element, attrs=nil)
        self << new_element = XML::Node.new(element.to_s, self.document)
        new_element.add_attributes(attrs)
        return new_element
      end

      # In nokogiri the "text" method was an alias for the "content" method,
      # which returns the text for this node plus all it's child nodes.
      #
      # This method has been redefined to only return this node's text.
      # If you need the text of all child nodes, use the "content" or
      # "inner_text" method.
      #
      def text
        self.children.each do |node|
          if node.node_type == TEXT_NODE
            if node.content && node.content.rstrip.length > 0
              return node.content
            end
          end
        end

        return nil
      end

      # Duplicates the REXML::Element#text= method. This finds the text node
      # and updates its content.
      #
      def text=(string)
        self.children.each do |node|
          if node.node_type == TEXT_NODE
            node.content = string.to_s
            return node.content
          end
        end

        self << XML::Text.new(string.to_s, self.doc)
      end

      # Simulates the REXML::Element#write method. Howevever, both the
      # +transitive+ and +ie_hack+ parameters are ignored. They are only
      # present for API compatibility.
      #
      # Note that this method has been deprecated in REXML in favor
      # of formatters.
      #
      def write(io_handle, indent=-1, transitive=false, ie_hack=false)
        options = {:indent => (indent >= 0 ? indent : 0)}

        if String === io_handle
          io_handle.replace(self.to_xml(options))
        else
          io_handle << self.to_xml(options)
        end
      end

      # Duplicates the REXML::Element#each_element method.
      def each_element (xpath="*", &block)
        self.find_match(xpath).each{ |n| yield n }
      end

      # Duplicates the REXML::Element#root method.
      def root
        return nil unless self.document
        self.document.root
      end

      # Duplicates the REXML::Element#has_elements? method. Note that
      # this verifies that there are elements, not just a text node.
      #
      def has_elements?
        self.each_element{ |e| return true }
        return false
      end
    end  # class Node

    class Document
      # Simulates the REXML::Document#write method. Howevever, both the
      # +transitive+ and +ie_hack+ parameters are ignored. They are only
      # present for API compatibility.
      #
      # Note that this method has been deprecated in REXML in favor
      # of formatters.
      #
      def write(io_handle, indent=-1, transitive=false, ie_hack=false)
        options = {:indent => (indent >= 0 ? indent : 0)}

        if String === io_handle
          io_handle.replace(self.to_xml(options))
        else
          io_handle << self.to_xml(options)
        end
      end

      # Duplicates the REXML::Element#root method.
      def add_element(name, attrs=nil)
        self.root = new_element = XML::Node.new(name, self)
        self.root.add_attributes(attrs) if attrs

        new_element
      end
    end  # class Document
  end  # module XML
end  # module Nokogiri
