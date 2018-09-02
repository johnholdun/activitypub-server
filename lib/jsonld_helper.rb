module JsonLdHelper
  def equals_or_includes?(haystack, needle)
    haystack.is_a?(Array) ? haystack.include?(needle) : haystack == needle
  end

  def value_or_id(value)
    value.is_a?(String) || value.nil? ? value : value['id']
  end

  def supported_context?(json)
    json && equals_or_includes?(json['@context'], 'https://www.w3.org/ns/activitystreams')
  end
end
