# ValiControl — MVP 0.2

Aplicativo Flutter para acompanhar produtos e datas de validade.

## O que já funciona
- Painel com totais de produtos em dia, em atenção e vencidos.
- Cadastro de produto com nome, marca, quantidade e data de validade.
- Busca por nome ou marca.
- Tela de alertas para itens vencidos ou que vencem em até 7 dias.
- Salvamento local automático dos produtos com `shared_preferences`; os dados continuam disponíveis após fechar e reabrir o app no mesmo aparelho.
- Navegação inferior entre Início, Produtos, Scanner, Alertas e Perfil.

## Executar no computador
É necessário ter o Flutter SDK instalado e um emulador Android ou celular conectado.

```bash
flutter pub get
flutter run
```

## Gerar APK de teste

```bash
flutter build apk --debug
```

O arquivo deverá ser gerado em `build/app/outputs/flutter-apk/app-debug.apk`.

## Limitações atuais
Esta é uma versão inicial. O scanner real, notificações do sistema, login, edição/exclusão de produtos e sincronização entre celulares ainda precisam ser implementados. O armazenamento atual é local e não sincroniza com outros aparelhos.

## Gerar o APK automaticamente pelo GitHub
Este projeto inclui o workflow `.github/workflows/build-apk.yml`. Para usá-lo:
1. Crie um repositório no GitHub e envie todos os arquivos desta pasta para ele.
2. Abra a aba **Actions** do repositório.
3. Selecione **Build ValiControl APK** e clique em **Run workflow** (ou aguarde o build após enviar para `main`/`master`).
4. Quando terminar com sucesso, abra a execução e baixe o artefato **valicontrol-debug-apk**.
5. Extraia o ZIP do artefato para obter `app-debug.apk` e transfira-o para o Android para instalar.

O APK de debug serve para teste. Para publicar na Play Store será necessário gerar uma versão assinada.
