feature 'Page' ,:focus do
  specify 'Messaging' do
    visit 'https://localhost:8080/'

    # binding.pry

    sleep 1

    expect( page ).to have_content 'Welcome'
  end
end