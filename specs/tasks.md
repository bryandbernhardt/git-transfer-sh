# Tarefas

| ID | Tarefa | Origem | Depende de | Concluída quando |
|---|---|---|---|---|
| T-01 | Inicializar script principal base e ambiente do ShellSpec | Constituição | - | Script `.sh` executa (Hello World) e suite do ShellSpec roda com sucesso sem erros estruturais |
| T-02 | Criar bateria de testes unitários para todo o fluxo (TDD) | RF-01 a RF-06 | T-01 | Testes unitários falham (esperando implementação) |
| T-03 | Implementar captura de inputs (e-mails) e criação do repositório destino | RF-01, RF-02 | T-02 | Script recebe e-mails, cria pasta e inicializa `git init` vazio com sucesso |
| T-04 | Implementar leitura e espelhamento de commits (datas, extensões genéricas) | RF-03, RN-01 | T-03 | Arquivos criados correspondem às extensões originais com texto Lorem Ipsum e mensagens genéricas |
| T-05 | Implementar persistência de hashes e lógica de pular commits já copiados | RF-04, RF-05, RN-01 | T-04 | Hash salvo no dotfile `.processed_commits`. Commits já presentes no dotfile não são recopiados. Reprocessa se hash for removido. |
| T-06 | Implementar tratamento para casos de borda (merge commits e empty commits) | Casos de Borda | T-04 | Commits de merge são pulados/tratados e flag `--allow-empty` é respeitada |
| T-07 | Implementar feedback de progresso no terminal | RF-06 | T-05 | Terminal exibe total de commits, quantidade na fila e progresso atualizado |
| T-08 | Validar execução final e compatibilidade de OS (Linux/MacOS/Windows) | Constituição, CA 1 a 4 | T-07 | Testes finais do ShellSpec passam 100%. `git log` no destino é idêntico nas datas sem vazar código/mensagem. |
| T-09 | Implementar um workflow para o github executar os testes unitários | @constitution.md, @plan.md | T-08 | Workflow roda e executa os testes do ShellSpec com sucesso |
