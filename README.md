# BlazeDemo Performance Test

## Link do repositorio
Repositorio publico no GitHub:

`https://github.com/LuisLipinski/SouthSystem_Blazedemo.git`

## Objetivo
Automacao de teste de performance para o fluxo de compra de passagem no site:

- URL: https://www.blazedemo.com
- Ferramenta: Apache JMeter 5.6.3

## Cenario testado
Compra de passagem com sucesso:

1. Abrir home
2. Buscar voos
3. Escolher o voo
4. Finalizar compra
5. Validar mensagem: "Thank you for your purchase today!"

## Criterio de aceitacao

1. 250 requisicoes por segundo
2. Tempo de resposta percentil 90 menor que 2 segundos

## Estrategia de teste

### Teste de carga
- Arquivo: `jmeter/blazedemo_load_test.jmx`
- Grupo ativo: Load Thread Group
- Usuarios: 330
- Ramp-up: 60s
- Duracao: 180s
- Throttle (ConstantThroughputTimer): 15000 amostras/min = 250 req/s alvo

### Teste de pico
- Arquivo: `jmeter/blazedemo_spike_test.jmx`
- Grupo ativo: Spike Thread Group
- Usuarios: 450
- Ramp-up: 8s
- Duracao: 120s
- Ramp-up abrupto simula spike real de trafego

Observacao:
- Cada script limpa o `.jtl` e a pasta de dashboard anterior antes de executar.
- Isso evita mistura de resultados entre execucoes.

## Como executar

### Pre-requisitos

1. Java 8+ instalado e disponivel no PATH
2. JMeter 5.6.3

### Windows (via scripts .bat)

Os scripts tentam primeiro o caminho local:

`C:\Users\Usuario\Documents\apache-jmeter-5.6.3\bin\jmeter.bat`

Se nao encontrar, usam `jmeter` no PATH.

### Executar carga

```bat
run_load_test.bat
```

Saidas:

1. `results/load_test_results.jtl`
2. `results/load_report/index.html`

### Executar pico

```bat
run_spike_test.bat
```

Saidas:

1. `results/spike_test_results.jtl`
2. `results/spike_report/index.html`

### Linux e macOS (via CLI)

No Linux/macOS, execute diretamente com o comando `jmeter`.
Se o comando nao estiver no PATH, use o caminho completo para `jmeter`.

Executar carga:

```bash
jmeter -n -t jmeter/blazedemo_load_test.jmx -l results/load_test_results.jtl -e -o results/load_report
```

Executar pico:

```bash
jmeter -n -t jmeter/blazedemo_spike_test.jmx -l results/spike_test_results.jtl -e -o results/spike_report
```

Saidas:

1. `results/load_test_results.jtl`
2. `results/load_report/index.html`
3. `results/spike_test_results.jtl`
4. `results/spike_report/index.html`

Importante:

1. O parametro `-o` exige pasta vazia ou inexistente.
2. Se necessario, remova pastas antigas antes de gerar o dashboard:

```bash
rm -rf results/load_report results/spike_report
```

## Relatorio de execucao

Rodada oficial considerada neste README:

1. Data: 2026-04-12
2. Load: 330 usuarios, ramp-up 60s, duracao 180s
3. Spike: 450 usuarios, ramp-up 8s, duracao 120s
4. Motivo da escolha: rodada completa, sem erros e com artefatos preservados no repositorio

Fontes utilizadas:

1. `results/load_report/statistics.json`
2. `results/spike_report/statistics.json`

## Evolucao de tuning

| Execucao | Load config | Spike config | Load req/s aprox | Load P90 | Load erro | Spike req/s aprox | Spike P90 | Spike erro | Leitura |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Inicial | 150 usuarios / 60s | 250 usuarios / 10s | 110.61 | 8.79s | 0.36% | 131.43 | 11.55s | 7.34% | Muito abaixo do alvo |
| Tuning 1 | 300 usuarios / 60s | 500 usuarios / 5s | 242.75 | 1.46s | 0.00% | 246.25 | 3.60s | 0.27% | Melhor desempenho observado |
| Tuning 2 oficial | 330 usuarios / 60s | 450 usuarios / 8s | 243.80 | 1.48s | 0.00% | 201.80 | 8.15s | 0.00% | Melhor evidência estável preservada |

Observacao:

1. Uma rerun adicional da configuracao 300/500 foi descartada porque o spike travou no fechamento do JMeter e nao gerou dashboard final.
2. Isso reforca a instabilidade do ambiente publico do BlazeDemo sob carga mais agressiva.

## Melhor configuracao observada

Melhor desempenho observado na evolucao: `Load 300 / Spike 500`.

Motivos:

1. Foi a configuracao que mais se aproximou da meta de 250 req/s tanto em load quanto em spike.
2. Entregou o melhor P90 de spike entre as rodadas com throughput alto (3.60s), mesmo ainda acima do SLA.
3. Manteve taxa de erro baixa no spike (0.27%).

Decisao para entrega:

1. A configuracao mantida nos arquivos do projeto e nos artefatos oficiais foi `Load 330 / Spike 450`.
2. Motivo: rodada completa, sem erro, com relatorios consistentes e reproduziveis dentro do repositorio.
3. A configuracao 300/500 ficou registrada na tabela de tuning como melhor desempenho observado, mas nao foi mantida como oficial porque a rerun posterior apresentou instabilidade no fechamento do teste.

### Resultado - Load Test

- Fluxo principal: Buy Ticket Flow
- Throughput da transacao: 60.95 transacoes/s
- Requisicoes/s aproximadas no fluxo: 60.95 x 4 = 243.80 req/s
- P90 (`pct1ResTime`): 1478 ms (1.48 s)
- Erro no fluxo: 0.00%

### Resultado - Spike Test

- Fluxo principal: Buy Ticket Flow - Spike
- Throughput da transacao: 50.45 transacoes/s
- Requisicoes/s aproximadas no fluxo: 50.45 x 4 = 201.80 req/s
- P90 (`pct1ResTime`): 8149.4 ms (8.15 s)
- Erro no fluxo: 0.00%

## Conclusao do criterio de aceitacao

Nao atendido.

Motivos:

1. Vazao abaixo do esperado em ambos os testes (243.80 e 201.80 req/s vs 250 req/s).
2. P90 atende no load (1.48s), mas nao atende no spike (8.15s).
3. No spike, mesmo sem erros, a latencia sob aumento abrupto ainda ficou alta para o SLA.

## Analise de raiz

Por que o criterio nao foi atingido?

O throughput real e limitado pela combinacao entre o numero de threads e o tempo de resposta medio do servidor:

```
Throughput max = Threads / (Avg response time em segundos)
Req/s max (HTTP) = Throughput max * 4 (requisicoes por fluxo)
```

Registros do load test anterior (150 threads):

- Tempo medio do fluxo: 3.73s
- Throughput maximo possivel: 150 / 3.73 = 40.2 transacoes/s
- Req/s maximo: 40.2 * 4 = 160.8 req/s

O ConstantThroughputTimer foi configurado em 15000 amostras/min (250 req/s), mas como o pool de threads nao conseguia entregar mais que ~160 req/s, o timer nao tinha efeito pratico: as threads eram o gargalo.

Para atingir 250 req/s com fluxo de 4 requisicoes e avg de 3.73s:

```
Threads necessarias = (250 req/s / 4) * 3.73s = 233 threads
Com margem de 30%: ~300 threads
```

Por isso o load test foi ajustado para 330 threads na rodada oficial.

Limitacao do ambiente BlazeDemo:
O blazedemo.com e um ambiente publico de demonstracao, compartilhado entre todos os usuarios. A latencia observada (P90 > 8s) nao reflete um sistema saudavel: indica que o servidor comeca a degradar sob carga. Em um sistema real com infra dedicada, os tempos seriam significativamente menores e o criterio de 250 req/s com P90 < 2s seria muito mais alcancavel.

## Propostas de melhoria

### Se o objetivo e atingir 250 req/s no BlazeDemo

1. Aumentar o numero de threads progressivamente (330, 450, 550) ate saturar a vazao alvo.
2. Monitorar se o aumento de threads gera aumento proporcional de throughput ou apenas de erros.
3. Se o servidor comecar a retornar erros 5xx, a limitacao e do backend, nao do JMeter.

### Se o objetivo e demostrar a capacidade do script

1. Usar um ambiente dedicado (ex: aplicacao local com Docker, Spring Boot, ou ambiente de staging).
2. Com servidor dedicado, a latencia esperada para fluxos simples e < 500ms, o que permite atingir facilmente 250 req/s com 150-200 threads.
3. Calcular antes quantas threads sao necessarias: `Threads = TPS_alvo * Avg_response_time`.

### Melhorias tecnicas no script JMeter

1. Remover listeners `View Results Tree` do modo batch para reduzir overhead de memoria.
2. Adicionar `DurationAssertion` por sampler para garantir SLA por requisicao, nao so pelo fluxo.
3. Adicionar `ResponseCodeAssertion` para tratar redirects inesperados como falha.
4. Usar o `bzm - Concurrency Thread Group` (plugin JMeter) no lugar do ThreadGroup padrao para controle de concorrencia mais preciso e com grafico de rampa suave.
5. Parametrizar origens e destinos de voo via CSV para variar dados e evitar cache do servidor.

## Evidencias

1. Dashboard carga: `results/load_report/index.html`
2. Dashboard pico: `results/spike_report/index.html`
3. Log carga: `results/load_test_results.jtl`
4. Log pico: `results/spike_test_results.jtl`
5. Screenshot carga: `docs/screenshots/load_dashboard.png`
6. Screenshot pico: `docs/screenshots/spike_dashboard.png`
7. Arquivo da rodada oficial arquivada: `results/experiments/cfg_load330_spike450`
8. Arquivo da rerun invalida arquivada: `results/experiments/cfg_load300_spike500_rerun_invalid`

## Consideracoes finais

1. Os avisos `StatusConsoleListener` vistos na execucao do JMeter sao warnings de plugin scan e nao impedem o teste.
2. A avaliacao principal foi feita no fluxo transacional fim-a-fim de compra, que representa melhor o cenario de negocio solicitado.

