feature 'Page' do
  specify 'Messaging' do
    visit '/'

    expect( page ).to have_content 'Welcome'
  end
end