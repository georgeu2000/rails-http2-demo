feature 'Page' do
  specify 'Index' do
    visit 'https://localhost:8080/'

    # binding.pry

    expect( page ).to have_content 'Welcome'
  end

  specify 'Push' do
    visit 'https://localhost:8080/push'

    expect( page ).to have_content 'push'
  end

  specify 'Assets' do
    visit 'https://localhost:8080/assets/main.css'

    expect( page ).to have_content 'body'
  end

  specify 'Favicon' do
    visit 'https://localhost:8080/favicon.ico'

    expect( page ).to have_content ''
  end
end