class HostMetaRoute < Route
  def call
    headers['Vary'] = 'Accept'
    headers['Content-Type'] = 'application/xrd+xml; charset=utf-8'
    headers['Cache-Control'] = 'max-age=259200, public'

    finish <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
  <Link rel="lrdd" type="application/xrd+xml" template="#{BASE_URL}/.well-known/webfinger?resource={uri}"/>
</XRD>
XML
  end
end
