# Documento de Especificação: Git Transfer SH

## Problema 
Programadores que utilizam plataformas e contas corporativas não conseguem manter seus gráficos de contribuição e estatísticas de linguagens atualizados em seus perfis pessoais do GitHub, pois o código da empresa não pode ser misturado com repositórios pessoais.

## Objetivo 
Fornecer uma ferramenta de linha de comando (CLI) que extraia os metadados e a volumetria dos commits de um desenvolvedor em um repositório corporativo, gerando um novo repositório local e anonimizado. Este novo repositório espelhará o histórico (datas e linguagens) para ser enviado ao GitHub pessoal, sem vazar uma única linha do código original ou mensagens sensíveis.

## Usuários 
- **Programador:** Executa o script via terminal em sua própria máquina.

## Histórias de Usuário
- **HU-01:** Como programador, quero rodar o script de dentro da pasta do repositório da empresa, informando meu e-mail atual (origem) e meu e-mail pessoal (destino), para que a ferramenta saiba quais commits deve espelhar.
- **HU-02:** Como programador, quero que o novo repositório gerado possua apenas arquivos com textos genéricos (ex: Lorem Ipsum) nas mesmas extensões e na mesma volumetria dos originais (incluindo exclusões de arquivos). Quero que as mensagens de commit originais sejam substituídas por mensagens genéricas, preservando apenas as datas (timestamps) exatas do passado, para que meu gráfico do GitHub seja reconstruído com precisão e segurança.
- **HU-03:** Como programador, quero executar essa ferramenta como um arquivo único em meu sistema operacional, sem precisar instalar bibliotecas extras ou pacotes (assumindo que eu já tenha o Git instalado localmente).

## Requisitos Funcionais 
- **RF-01:** O script deve ser executado no diretório atual do repositório corporativo e solicitar/receber os e-mails de origem e destino.
- **RF-02:** O script deve criar uma nova pasta na máquina do usuário para inicializar o repositório espelho.
- **RF-03:** Para cada commit do autor na origem, o script deve gerar um commit correspondente no destino com a data original (timestamp), e-mail de destino, arquivos contendo texto genérico (respeitando as extensões, adições e exclusões originais) e uma **mensagem de commit genérica** (ex: "Commit espelhado"). A mensagem original do commit **não** deve ser copiada.
- **RF-04:** O sistema deve registrar o *hash identificador (SHA-1)* de cada commit processado em um arquivo local de controle (ex: `.commits_copiados`), para evitar duplicações em execuções futuras.
- **RF-05:** Se o usuário manipular o arquivo de controle e remover o *hash* de um commit, o sistema deve ser capaz de reprocessar esse commit na próxima execução.
- **RF-06:** O script deve exibir no terminal o progresso da operação: total de commits encontrados, quantos já estavam copiados e quantos estão sendo processados agora.
- **RF-07:** O script deve criar um arquivo para cada extensão existente, caso o arquivo já exista, apenas aplicar as alterações ao arquivo já existente.
- **RF-08:** O script deve criar todos os arquivos na raiz do repositório clone, sem copiar a estrutura de arquivos e pastas do projeto de origem.

## Regras de Negócio 
- **RN-01:** O arquivo de controle deve armazenar apenas o *hash (SHA-1)* do commit original. Sob nenhuma hipótese o código-fonte original ou a mensagem original do commit devem ser lidos para armazenamento ou replicados no destino.
- **RN-02:** O sistema é responsável apenas por gerar o repositório localmente. O *push* (envio) para a URL pública no GitHub é de total responsabilidade do usuário, de forma manual.

## Casos de Borda (Mapeados para Testes)
- **Merge Commits:** Commits de merge geralmente não possuem alterações diretas de código do usuário, apenas unem branches. O script deve saber ignorá-los ou tratá-los para não quebrar a geração dos arquivos falsos.
- **Commits Vazios:** Commits gerados com a flag `--allow-empty` devem ser replicados como vazios no destino, usando também uma mensagem genérica.

## Fora de Escopo 
- Autenticação com APIs do GitHub, GitLab ou Bitbucket.
- Envio automatizado (*push*) para servidores remotos.
- Instalação de um cliente Git na máquina do usuário.

## Critérios de Aceite 
1. Ao executar o script pela segunda vez consecutiva no mesmo repositório, o terminal deve exibir a mensagem de que não possui commits novos e encerrar sem criar dados duplicados.
2. O histórico do repositório espelho gerado (`git log`) deve exibir as datas passadas exatamente iguais às do repositório da empresa.
3. Ao inspecionar os arquivos gerados e o histórico de commits (`git log`) no repositório espelho, nenhuma variável, lógica, texto do código corporativo ou **mensagem original de commit** deve estar presente. O conteúdo dos arquivos deve corresponder às extensões alteradas no commit original.
4. O repositório final gerado deve permitir que o usuário faça `git remote add` e `git push` manualmente sem causar conflitos estruturais.