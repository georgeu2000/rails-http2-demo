describe 'Requests' do
  let( :client ){ NetHttp2::Client.new( "https://localhost:8080" )}

  specify 'GET headers and URL params' do
    response = client.call(:get, '/mirror?name=matz', headers:{ 'accept' => 'text/html' })
    client.close

    expect( response.ok?  ).to eq true
    expect( response.status ).to eq '200'
    expect( response.headers[ 'content-type' ]).to include 'text/html'

    expect( response.body ).to include 'Accept'
    expect( response.body ).to include 'text/html'
    expect( response.body ).to include 'name'
    expect( response.body ).to include 'matz'
  end

  specify 'GET custom headers' do
    response = client.call(:get, '/mirror', headers:{ 'x-custom-header' => 'custom-value' })
    client.close

    expect( response.ok?  ).to eq true
    expect( response.status ).to eq '200'

    expect( response.body ).to include 'X-Custom-Header'
    expect( response.body ).to include 'custom-value'
  end
end