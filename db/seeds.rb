# frozen_string_literal: true

puts 'Criando seed de dados...'

user = User.find_or_create_by!(email: 'teste@exemplo.com') do |u|
  u.name = 'Adminstrador'
  u.password = '123456'
  u.password_confirmation = '123456'
  u.admin = true
end

puts "Usuário criado: #{user.email}"

contatos = [
  { name: 'Ana Silva Santos', phone: '(11) 99999-0001' },
  { name: 'Bruno Oliveira Costa', phone: '(21) 99999-0002' },
  { name: 'Carlos Pereira Lima', phone: '(31) 99999-0003' },
  { name: 'Diana Ferreira Alves', phone: '(41) 99999-0004' },
  { name: 'Eduardo Rodrigues', phone: '(51) 99999-0005' },
  { name: 'Fernanda Carvalho', phone: '(61) 99999-0006' },
  { name: 'Gabriel Almeida', phone: '(71) 99999-0007' },
  { name: 'Helena Gomes', phone: '(81) 99999-0008' },
  { name: 'Igor Martins', phone: '(91) 99999-0009' },
  { name: 'Julia Dias', phone: '(11) 98888-0010' },
  { name: 'Kleber Ribeiro', phone: '(21) 98888-0011' },
  { name: 'Larissa Castro', phone: '(31) 98888-0012' },
  { name: 'Marcos Barbosa', phone: '(41) 98888-0013' },
  { name: 'Natalia Rocha', phone: '(51) 98888-0014' },
  { name: 'Otávio Mendes', phone: '(61) 98888-0015' },
  { name: 'Paula Santos', phone: '(71) 98888-0016' },
  { name: 'Quintino Campos', phone: '(81) 98888-0017' },
  { name: 'Raquel Lima', phone: '(91) 98888-0018' },
  { name: 'Samuel Torres', phone: '(11) 97777-0019' },
  { name: 'Tatiana Alves', phone: '(21) 97777-0020' },
  { name: 'Ulisses Costa', phone: '(31) 97777-0021' },
  { name: 'Vanessa Pereira', phone: '(41) 97777-0022' },
  { name: 'Wagner Ferreira', phone: '(51) 97777-0023' },
  { name: 'Xena Rodrigues', phone: '(61) 97777-0024' },
  { name: 'Yuri Carvalho', phone: '(71) 97777-0025' },
  { name: 'Zara Almeida', phone: '(81) 97777-0026' },
  { name: 'André Borges', phone: '(91) 97777-0027' },
  { name: 'Beatriz Gomes', phone: '(11) 96666-0028' },
  { name: 'Carlos Eduardo', phone: '(21) 96666-0029' },
  { name: 'Daniela Martins', phone: '(31) 96666-0030' },
  { name: 'Emmanoel Dias', phone: '(41) 96666-0031' },
  { name: 'Fabiana Ribeiro', phone: '(51) 96666-0032' },
  { name: 'Gustavo Castro', phone: '(61) 96666-0033' },
  { name: 'Hannah Barbosa', phone: '(71) 96666-0034' },
  { name: 'Isaac Rocha', phone: '(81) 96666-0035' },
  { name: 'Joana Mendes', phone: '(91) 96666-0036' },
  { name: 'Kevin Santos', phone: '(11) 95555-0037' },
  { name: 'Lorena Campos', phone: '(21) 95555-0038' },
  { name: 'Mateus Lima', phone: '(31) 95555-0039' },
  { name: 'Nathalia Torres', phone: '(41) 95555-0040' },
  { name: 'Olivia Alves', phone: '(51) 95555-0041' },
  { name: 'Paulo Costa', phone: '(61) 95555-0042' },
  { name: 'Queila Pereira', phone: '(71) 95555-0043' },
  { name: 'Renato Ferreira', phone: '(81) 95555-0044' },
  { name: 'Silvia Rodrigues', phone: '(91) 95555-0045' },
  { name: 'Thiago Carvalho', phone: '(11) 94444-0046' },
  { name: 'Ursula Almeida', phone: '(21) 94444-0047' },
  { name: 'Vinícius Gomes', phone: '(31) 94444-0048' },
  { name: 'Wendy Martins', phone: '(41) 94444-0049' },
  { name: 'Yago Dias', phone: '(51) 94444-0050' }
]

contatos.each do |contato|
  Contact.find_or_create_by!(name: contato[:name], user: user) do |c|
    c.phone = contato[:phone]
  end
end

puts "Criados #{contatos.length} contatos para #{user.name}"
puts 'Seed concluído com sucesso!'
