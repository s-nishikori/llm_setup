# Vast.ai Qwen + vLLM セットアップ

Vast.ai のGPUインスタンスへSSH接続し、Qwen系モデルをvLLMのOpenAI互換APIとして起動するための再現可能な構成です。インスタンスを破棄しても、GitHubからcloneして復元できます。

> 想定: Vast.ai のvLLMテンプレート（Ubuntu、NVIDIA GPU、`vllm`導入済み）。モデル本体、`.env`、APIキー、Hugging FaceトークンはGitに保存しません。

## 1. Vast.aiインスタンスを用意

Vast.aiでGPUを借り、vLLMテンプレートから起動します。ディスク容量はモデル、キャッシュ、コンテナを含め余裕を持たせてください。SSH接続情報はVast.aiの画面に表示される値を使います。

```bash
ssh -p <SSH_PORT> root@<VAST_HOST>
```

リポジトリを取得して環境を診断します。

```bash
git clone https://github.com/<YOUR_NAME>/<YOUR_REPOSITORY>.git
cd <YOUR_REPOSITORY>
chmod +x scripts/*.sh
./scripts/check_env.sh
```

`nvidia-smi`、GPU名、CUDA、PyTorch、vLLMが確認できれば次へ進みます。vLLMがない汎用イメージの場合は、GPU世代に対応する公式vLLMイメージまたはVast.aiテンプレートへ切り替えるのが安全です。

## 2. 追加ツールと設定

```bash
python -m pip install -r requirements.txt
cp .env.example .env
nano .env
```

最低限、次を変更します。

- `MODEL_ID`: 使用するHugging FaceリポジトリID
- `VLLM_API_KEY`: `openssl rand -hex 32` などで生成した秘密値
- `HF_TOKEN`: gated/privateモデルの場合のみ設定

32GB GPUで27B級を動かす場合、BF16版は通常VRAMに収まらないため、対応するAWQ/GPTQ/FP8等の量子化モデルを選びます。量子化モデルは第三者配布の場合があるため、配布元、モデルカード、ライセンス、vLLM対応状況を確認してください。リポジトリには特定の非公式モデルIDを初期値として固定していません。

既定の`HOST=127.0.0.1`は、APIを外部へ直接公開しないための設定です。

## 3. モデルを取得

```bash
./scripts/download_model.sh
```

モデルは既定で`/workspace/models/qwen`へ保存されます。Vast.aiの永続ボリュームを使う場合は、そのマウント先に`MODEL_DIR`を変更してください。事前ダウンロードを省略して`start_vllm.sh`を実行すると、vLLMが`MODEL_ID`から直接取得します。

## 4. vLLMを起動

```bash
./scripts/start_vllm.sh
```

別のSSHセッションで確認します。

```bash
cd <YOUR_REPOSITORY>
./scripts/healthcheck.sh
```

VRAM不足の場合は、まず`.env`の`MAX_MODEL_LEN`または`GPU_MEMORY_UTILIZATION`を下げます。モデルが明示指定を必要とする場合のみ、例として`VLLM_EXTRA_ARGS=--quantization awq`を設定します。複数GPUでは`TENSOR_PARALLEL_SIZE`をGPU数に合わせます。

長時間稼働には`tmux`などを利用できます。

```bash
tmux new -s vllm
./scripts/start_vllm.sh
# Ctrl-b、続けて d でdetach
```

## 5. Windowsから安全に接続

Windows PowerShellでSSHトンネルを開いたままにします。

```powershell
ssh -N -L 8000:localhost:8000 -p <SSH_PORT> root@<VAST_HOST>
```

Windows側からは`http://localhost:8000/v1`へ接続できます。Windowsにもこのリポジトリをcloneし、そのディレクトリで次を実行します。

```powershell
$env:VLLM_API_KEY = '<.envと同じAPIキー>'
$env:SERVED_MODEL_NAME = 'qwen'
python -m pip install openai
python examples/client.py
```

ポート8000をVast.aiで公開する必要はありません。公開する場合は、APIキーだけに頼らずTLS、ファイアウォール、リバースプロキシ等も設定してください。

## 6. LM Studioと連携

LM Studioと連携できます。vLLMがOpenAI互換APIを提供しているためです。最も簡単な構成は次のとおりです。

### LM Studioで操作する

1. Vast.aiでvLLMを起動します。

   ```bash
   cd /workspace/llm_setup
   ./scripts/start_vllm.sh
   ```

2. WindowsでSSHトンネルを開きます。

   ```powershell
   ssh -N -L 8000:localhost:8000 -p <SSH_PORT> root@<VAST_HOST>
   ```

3. LM Studioに、公式Hubの[OpenAI-compatible endpoint adapter](https://lmstudio.ai/lmstudio/openai-compat-endpoint)を追加します。

4. アダプターの接続情報を設定します。

   ```text
   Base URL: http://localhost:8000/v1
   API Key:  Vast.ai側の.envにあるVLLM_API_KEY
   Model:    qwen
   ```

これで、LM Studioのチャット画面からVast.ai上のQwenを操作できます。ただし、このアダプター方式はLM Studio本体でローカルモデルを動かす通常構成とは異なるため、バージョンによって設定画面が変わる可能性があります。

LM Studio自身もOpenAI互換APIを提供していますが、それは基本的に「LM Studioをサーバーとして使う」方向です。ここではLM Studioをクライアントとして、SSHトンネル越しのvLLMへ接続します。詳しくは[LM Studio公式のOpenAI互換API資料](https://lmstudio.ai/docs/developer/openai-compat)を参照してください。

### さらに簡単にするなら

Windows側の`connect.bat`にVast.aiの接続先が設定済みなら、コマンドを毎回入力せず、次の順で起動できます。

1. `connect.bat`を起動し、SSHトンネルのウィンドウを開いたままにします。
2. `status.bat`を実行し、vLLMへの接続を確認します。
3. LM Studioを開き、上記のOpenAI-compatible endpoint adapterを選択してチャットします。

接続先が変わった場合は、`VAST_HOST`と`VAST_PORT`を環境変数で指定してから`connect.bat`を起動できます。

```powershell
$env:VAST_HOST = '<VAST_HOST>'
$env:VAST_PORT = '<SSH_PORT>'
.\connect.bat
```

## 7. GitHubへpush

GitHubで空のリポジトリを作成後、ローカルまたはVast.ai上で実行します。

```bash
git init
git add .
git commit -m "Add reproducible Vast.ai Qwen vLLM setup"
git branch -M main
git remote add origin https://github.com/<YOUR_NAME>/<YOUR_REPOSITORY>.git
git push -u origin main
```

push前に`git status`と`git diff --cached`を確認し、`.env`やトークンが含まれないことを必ず確認してください。

## 次回の復元

```bash
git clone https://github.com/<YOUR_NAME>/<YOUR_REPOSITORY>.git
cd <YOUR_REPOSITORY>
python -m pip install -r requirements.txt
cp .env.example .env
nano .env
./scripts/download_model.sh
./scripts/start_vllm.sh
```

動作確認後は、`./scripts/check_env.sh`の出力と、利用したVast.aiテンプレートまたはDockerイメージのタグを記録し、`latest`から既知の動作バージョンへ固定すると再現性が上がります。

## Dockerfile（任意）

Vast.aiのvLLMテンプレート内でDockerを二重起動する必要はありません。`Dockerfile`はカスタムテンプレートや別環境向けです。

```bash
docker build --build-arg VLLM_IMAGE=vllm/vllm-openai:<TESTED_TAG> -t qwen-vast .
docker run --gpus all --ipc=host --env-file .env -e HOST=0.0.0.0 \
  -p 127.0.0.1:8000:8000 \
  -v /workspace/models:/workspace/models qwen-vast
```

## 参考

- [Qwen公式Hugging Face](https://huggingface.co/Qwen)
- [vLLM公式ドキュメント](https://docs.vllm.ai/)
- [Vast.aiドキュメント](https://docs.vast.ai/)
