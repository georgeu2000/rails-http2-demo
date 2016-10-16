feature 'Page' ,:js do
  specify 'Messaging' do
    visit '/'

    binding.pry

    expect( page ).to have_content 'Welcome'
  end
end