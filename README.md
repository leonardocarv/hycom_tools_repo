# HYCOM Tools

Conjunto de scripts para automatizar o ciclo completo de pré-processamento e
execução do modelo oceanográfico **HYCOM** (HYbrid Coordinate Ocean Model):
geração de grade e batimetria, compilação, condições iniciais, forçantes,
aninhamento de grades e execução — controlados por um único arquivo de
configuração.

O objetivo é tornar a montagem de um experimento HYCOM **reprodutível e
parametrizada**: domínio, resolução, número de camadas verticais e tipo de
referência sigma são variáveis de entrada, de modo que testar e comparar
configurações se resume a editar a configuração e re-executar.

---

## Principais recursos

- **Fluxo de ponta a ponta** orquestrado por um script-mestre.
- **Aninhamento de grades** (domínio pai + domínios aninhados encadeados),
  com cálculo automático dos fatores de refinamento e das condições de
  contorno (portos de fronteira).
- **Estrutura vertical isopicnal** configurável (número de camadas e
  densidades-alvo), com suporte a sub-regiões com perfis distintos.
- **Seleção do tipo de referência sigma** (σ₀ ou σ₂) por parâmetro.
- **Condições iniciais e climatologia** a partir de WOA13 ou Levitus.
- **Forçante atmosférica** (CFSR / ERA-15), incluindo download dos dados.
- **Aporte fluvial** (rios) e **compilação automatizada** com verificação de
  compatibilidade entre a grade e o código-fonte.

---

## Requisitos

- Shell **KornShell** (`ksh`).
- Modelo **HYCOM** e o pacote de ferramentas de pré-processamento
  **HYCOM-tools (ALL)** instalados.
- **MPICH** (MPI) para a execução paralela do modelo.
- **MATLAB** (usado na detecção automática dos portos de fronteira no
  aninhamento).
- Utilitários padrão de sistema: `bc`, `date`, `grep`, `cut`, `tar`.
- Dados de entrada: climatologia (WOA13 / Levitus) e forçante atmosférica
  (CFSR / ERA-15).

---

## Estrutura do repositório

Os scripts ficam em `scritps/`:

| Arquivo | Função |
|---|---|
| `hycom_domain.input` | **Arquivo de configuração central.** Define paths do sistema, domínios (nome, coordenadas, dx/dy, nº de camadas, referência sigma) e período/modo da simulação. |
| `do_hycom_task.ksh` | **Script-mestre.** Orquestra todas as etapas para cada domínio configurado (grade → compilação → forçantes → execução). |
| `do_hycom_grid.ksh` | Gera a grade regional (`regional.grid`) e a batimetria a partir das coordenadas e do espaçamento definidos. |
| `do_hycom_grid_ATL.ksh` | Variante da geração de grade para o domínio do Atlântico. |
| `do_hycom_compilation.ksh` | Compila o HYCOM, verificando a compatibilidade do `dimensions.h` (idm, jdm, kdm) com a grade e recompilando quando necessário. |
| `do_blkdat.ksh` | Monta o `blkdat.input` (nº de camadas, dp00, flags) de forma consistente com o kdm e o sigma. |
| `do_iso_sigma.ksh` | Define a estrutura vertical isopicnal (densidades-alvo das camadas), com suporte a sub-regiões. |
| `do_levitus_sig.ksh` | Interpola a climatologia de Levitus para a grade/profundidade do modelo. |
| `do_woa_clim.ksh` | Interpola a climatologia WOA13 para a grade do modelo. |
| `do_relax.ksh` | Gera os campos de relaxação (climatologia) coerentes com a estrutura vertical. |
| `do_atm_forcing.ksh` | Interpola a forçante atmosférica (CFSR / ERA-15) para a grade do modelo. |
| `get_atm_data.ksh` | Baixa os dados atmosféricos (NCEP/CFSR) no formato do HYCOM. |
| `do_rivers.ksh` | Identifica e escreve os arquivos de aporte fluvial da região. |
| `do_nest_task.ksh` | Constrói a batimetria do domínio aninhado, interpola os campos do pai para o filho e gera as condições de contorno (`ports.input`). |
| `do_clim_task.ksh` | Executa uma simulação no modo climatológico. |
| `do_actual_task.ksh` | Executa uma simulação no modo "actual" (período de datas reais). |

Arquivos `*.old` e `*.32kdm` são versões anteriores/alternativas mantidas
como referência.

---

## Configuração

Antes de executar, ajuste o `scritps/hycom_domain.input`. Ele tem três seções:

1. **Paths do sistema** — diretório raiz do HYCOM, caminho das ferramentas de
   pré-processamento (ALL), diretório dos scripts e o bin do MPICH.
2. **Domínio espacial** — número de domínios (`max_domain`) e, para cada
   domínio `d0X`, o nome, latitudes (sul/norte), longitudes (oeste/leste),
   espaçamentos `dx`/`dy`, número de camadas (`kdm`) e a referência sigma
   (`sig`: `0` para σ₀ ou `2` para σ₂). Domínios são encadeados para
   aninhamento (`d01` é o pai, `d02` aninhado no `d01`, e assim por diante).
3. **Domínio temporal** — modo de execução (`clim` ou `actual`), datas de
   início e fim (formato `yyyymmdd`) e número de anos para rodadas
   climatológicas.

O formato de cada linha é `variável : valor : descrição`.

---

## Modo de usar

### Execução completa (recomendado)

Com o `hycom_domain.input` configurado, rode o script-mestre a partir do
diretório dos scripts:

```ksh
cd scritps
./do_hycom_task.ksh
```

Ele percorre os domínios configurados e, para cada um, gera a batimetria,
compila o modelo, prepara as forçantes e executa a simulação no modo
(`clim` ou `actual`) indicado na configuração.

### Execução por etapas

Os scripts também podem ser chamados individualmente. A maioria recebe o
índice do domínio (`grid_id`: `1` para o pai, `2` para o primeiro aninhado,
etc.) e, quando aplicável, o número de camadas (`kdm`) e a referência sigma:

```ksh
# Gerar grade e batimetria do domínio pai
./do_hycom_grid.ksh 1

# Compilar o modelo para o domínio 1, 22 camadas, sigma0
./do_hycom_compilation.ksh 1 22 0

# Definir a estrutura vertical isopicnal (domínio 1, 41 camadas, sigma0)
./do_iso_sigma.ksh 1 41 0

# Montar a batimetria e as condições de contorno do domínio aninhado (2)
./do_nest_task.ksh 2 20080905 20081125

# Rodar a climatologia (domínio 1, 22 camadas, sigma0, 5 anos)
./do_clim_task.ksh 1 22 0 5

# Rodar uma simulação "actual" (domínio 1, 22 camadas, sigma0, datas)
./do_actual_task.ksh 1 22 0 20080905 20081125
```

> As datas seguem o formato `yyyymmdd` e são convertidas internamente para o
> calendário de referência do HYCOM (dias a partir de 1900/12/31).

---

## Fluxo de trabalho

```
hycom_domain.input
        │
        ▼
do_hycom_task.ksh ── para cada domínio configurado:
        │
        ├── do_hycom_grid.ksh ........ grade + batimetria
        ├── do_hycom_compilation.ksh . compila o HYCOM
        ├── (aninhado) do_nest_task .. interpolação pai→filho + contornos
        ├── forçantes/clima .......... do_relax / do_woa_clim / do_atm_forcing / do_rivers
        └── do_clim_task | do_actual_task .. execução
```
