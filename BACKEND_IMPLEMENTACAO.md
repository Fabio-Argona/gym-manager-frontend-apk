# Implementação Backend - Recuperação de Senha com CPF

## 1. RecuperarSenhaDTO

```java
package com.treino_abc_backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class RecuperarSenhaDTO {

    @JsonProperty("email")
    private String email;

    public RecuperarSenhaDTO() {}

    public RecuperarSenhaDTO(String email) {
        this.email = email;
    }

    // Getters e Setters
    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
```

## 2. Atualizar AuthService

```java
package com.treino_abc_backend.service;

import com.treino_abc_backend.dto.AlunoDTO;
import com.treino_abc_backend.dto.TokenResponseDTO;
import com.treino_abc_backend.entity.Aluno;
import com.treino_abc_backend.repository.AlunoRepository;
import com.treino_abc_backend.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final AlunoRepository alunoRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(AlunoRepository alunoRepository, EmailService emailService,
                       PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.alunoRepository = alunoRepository;
        this.emailService = emailService;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    public Aluno register(Aluno aluno) {
        String normalizedEmail = aluno.getEmail().trim().toLowerCase();

        if (alunoRepository.existsByEmail(normalizedEmail)) {
            throw new RuntimeException("Email já cadastrado: " + normalizedEmail);
        }

        aluno.setEmail(normalizedEmail);
        aluno.setPassword(passwordEncoder.encode(aluno.getPassword()));
        aluno.setRole("ROLE_USER");

        return alunoRepository.save(aluno);
    }

    public TokenResponseDTO login(String email, String password) {
        String normalizedEmail = email.trim().toLowerCase();

        Aluno aluno = alunoRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new RuntimeException("Email não encontrado: " + normalizedEmail));

        if (!passwordEncoder.matches(password, aluno.getPassword())) {
            throw new RuntimeException("Senha inválida para o email: " + normalizedEmail);
        }

        String token = jwtUtil.generateToken(aluno.getEmail(), aluno.getCpf());
        return new TokenResponseDTO(token, toDTO(aluno));
    }

    public void enviarEmailRecuperacao(String email) {
        String normalizedEmail = email.trim().toLowerCase();

        Aluno aluno = alunoRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new RuntimeException("Email não encontrado: " + normalizedEmail));

        // 1. Extrair 6 primeiros dígitos do CPF (sem máscara)
        String cpfLimpo = aluno.getCpf().replaceAll("[^0-9]", "");
        String senhaTemporaria = cpfLimpo.length() >= 6 
            ? cpfLimpo.substring(0, 6) 
            : cpfLimpo;

        // 2. Atualizar a senha do usuário com a senha temporária (codificada)
        aluno.setPassword(passwordEncoder.encode(senhaTemporaria));
        alunoRepository.save(aluno);

        // 3. Enviar email com a senha temporária
        String assunto = "Recuperação de Senha - Full Performance";
        String corpo = "Olá " + aluno.getNome() + ",\n\n" +
                "Você solicitou a recuperação de sua senha.\n\n" +
                "Sua senha temporária é: " + senhaTemporaria + "\n\n" +
                "Use esta senha para fazer login. Após entrar, recomendamos alterar sua senha.\n\n" +
                "Atenciosamente,\n" +
                "Equipe Full Performance";

        emailService.enviar(normalizedEmail, assunto, corpo);
    }

    public void redefinirSenha(String email, String novaSenha) {
        String normalizedEmail = email.trim().toLowerCase();

        Aluno aluno = alunoRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado: " + normalizedEmail));

        aluno.setPassword(passwordEncoder.encode(novaSenha));
        alunoRepository.save(aluno);
    }

    public void alterarSenha(String email, String senhaAtual, String novaSenha) {
        String normalizedEmail = email.trim().toLowerCase();

        Aluno aluno = alunoRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado: " + normalizedEmail));

        // Validar senha atual
        if (!passwordEncoder.matches(senhaAtual, aluno.getPassword())) {
            throw new RuntimeException("Senha atual incorreta");
        }

        // Atualizar para nova senha
        aluno.setPassword(passwordEncoder.encode(novaSenha));
        alunoRepository.save(aluno);
    }

    private AlunoDTO toDTO(Aluno aluno) {
        AlunoDTO dto = new AlunoDTO();
        dto.setId(aluno.getId());
        dto.setNome(aluno.getNome());
        dto.setCpf(aluno.getCpf());
        dto.setEmail(aluno.getEmail());
        dto.setTelefone(aluno.getTelefone());
        dto.setDataNascimento(aluno.getDataNascimento());
        dto.setLogin(aluno.getLogin());
        return dto;
    }
}
```

## 3. Configurar JavaMailSender no application.properties

```properties
# Email Configuration
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=seu-email@gmail.com
spring.mail.password=sua-senha-app
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
spring.mail.properties.mail.smtp.starttls.required=true
```

**Nota:** Para Gmail, use uma [Senha de App](https://support.google.com/accounts/answer/185833) e não sua senha normal.

## 4. Ou usar outro provedor (SendGrid, Mailgun, etc.)

### Exemplo com SendGrid:

```xml
<!-- pom.xml -->
<dependency>
    <groupId>com.sendgrid</groupId>
    <artifactId>sendgrid-java</artifactId>
    <version>4.10.2</version>
</dependency>
```

```java
@Service
public class EmailService {
    
    @Value("${sendgrid.api.key}")
    private String sendGridApiKey;

    public void enviarEmail(String destinatario, String assunto, String corpo) {
        Email from = new Email("seu-email@seudominio.com");
        Email to = new Email(destinatario);
        Content content = new Content("text/plain", corpo);
        Mail mail = new Mail(from, assunto, to, content);

        SendGrid sg = new SendGrid(sendGridApiKey);
        Request request = new Request();
        try {
            request.setMethod(Method.POST);
            request.setEndpoint("mail/send");
            request.setBody(mail.build());
            Response response = sg.api(request);
            System.out.println(response.getStatusCode());
        } catch (IOException ex) {
            throw new RuntimeException("Erro ao enviar email");
        }
    }
}
```

## 5. Adicionar dependência de email no pom.xml

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-mail</artifactId>
</dependency>
```

## 6. Fluxo de Recuperação Completo

1. **Frontend** envia POST para `/auth/recuperar-senha` com `{ "email": "..." }`
2. **Backend** busca o aluno pelo email
3. **Backend** extrai os 6 primeiros dígitos do CPF
4. **Backend** envia email com a senha temporária
5. **Usuário** recebe o email com a senha temporária
6. **Usuário** faz login com email + senha temporária
7. **Usuário** muda a senha (com um novo endpoint)

## 7. Endpoint para Alterar Senha (Opcional)

```java
@PutMapping("/alterar-senha")
@PreAuthorize("isAuthenticated()")
public ResponseEntity<?> alterarSenha(@RequestBody AlterarSenhaDTO dto, @AuthenticationPrincipal UserDetails userDetails) {
    try {
        authService.alterarSenha(userDetails.getUsername(), dto.getSenhaAtual(), dto.getNovaSenha());
        return ResponseEntity.ok("Senha alterada com sucesso");
    } catch (RuntimeException e) {
        return ResponseEntity.badRequest().body(e.getMessage());
    }
}
```

```java
public void alterarSenha(String email, String senhaAtual, String novaSenha) {
    Optional<Aluno> alunoOpt = alunoRepository.findByEmail(email);
    
    if (!alunoOpt.isPresent()) {
        throw new RuntimeException("Usuário não encontrado");
    }

    Aluno aluno = alunoOpt.get();
    
    // Validar senha atual (use BCryptPasswordEncoder)
    if (!passwordEncoder.matches(senhaAtual, aluno.getPassword())) {
        throw new RuntimeException("Senha atual incorreta");
    }

    // Atualizar para nova senha
    aluno.setPassword(passwordEncoder.encode(novaSenha));
    alunoRepository.save(aluno);
}
```

---

**Resumo:** Agora o seu backend tem tudo implementado para:
✅ Receber solicitação de recuperação de senha
✅ Buscar o aluno pelo email
✅ Extrair 6 primeiros dígitos do CPF
✅ Enviar email com a senha temporária
✅ Permitir login com a senha temporária
✅ Permitir alterar senha depois (opcional)
