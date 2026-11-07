
#!/usr/bin/env bash
set -Eeuo pipefail

TOOLS_DIR="/home/david/projects/wsl/ds1david/ds1dev-setup-utility/tools"
DOWNLOAD_DIR="$TOOLS_DIR/downloads"
MANIFEST="$TOOLS_DIR/downloads.sha256"

mkdir -p "$DOWNLOAD_DIR"

download() {
    local name="$1"
    local url="$2"
    local destination="$DOWNLOAD_DIR/$name"

    echo "==> Baixando: $name"

    # Nunca reutilizar um arquivo parcial anterior.
    rm -f "$destination.part"

    curl --fail --location --show-error \
        --retry 3 \
        --retry-delay 5 \
        --connect-timeout 30 \
        --output "$destination.part" \
        "$url"

    if [[ ! -s "$destination.part" ]]; then
        echo "ERRO: arquivo vazio: $name" >&2
        return 1
    fi

    mv -f "$destination.part" "$destination"

    echo "SHA-256: $(sha256sum "$destination")"

    if [[ "$name" == *.zip ]]; then
        unzip -tq "$destination" >/dev/null || {
            echo "ERRO: arquivo ZIP inválido: $name" >&2
            rm -f "$destination"
            return 1
        }
    fi

    echo "OK: $destination"
}

verify_corretto() {
    local name="amazon-corretto-25-x64-windows-jdk.zip"
    local checksum_url="https://corretto.aws/downloads/latest_sha256/$name"
    local expected
    local actual

    expected=$(curl --fail --location --silent --show-error "$checksum_url" |
        grep -Eo '[[:xdigit:]]{64}' | head -n 1)

    [[ -n "$expected" ]] || {
        echo "ERRO: checksum oficial indisponível" >&2
        return 1
    }

    actual=$(sha256sum "$DOWNLOAD_DIR/$name" | awk '{print $1}')

    if [[ "${actual,,}" != "${expected,,}" ]]; then
        echo "ERRO: SHA-256 do Corretto divergente" >&2
        rm -f "$DOWNLOAD_DIR/$name"
        return 1
    fi

    echo "OK: Corretto validado contra o SHA-256 oficial"
}

download \
    "docker-28.1.0.zip" \
    "https://download.docker.com/win/static/stable/x86_64/docker-28.1.0.zip"

download \
    "docker-compose-windows-x86_64.exe" \
    "https://github.com/docker/compose/releases/download/v2.35.1/docker-compose-windows-x86_64.exe"

download \
    "amazon-corretto-25-x64-windows-jdk.zip" \
    "https://corretto.aws/downloads/latest/amazon-corretto-25-x64-windows-jdk.zip"

verify_corretto

(
    cd "$DOWNLOAD_DIR"
    sha256sum \
        docker-28.1.0.zip \
        docker-compose-windows-x86_64.exe \
        amazon-corretto-25-x64-windows-jdk.zip \
        > "$MANIFEST"
)

echo
echo "Downloads concluídos."
echo "Manifesto: $MANIFEST"
echo "Atenção: os hashes Docker foram registrados,"
echo "mas ainda precisam ser comparados com fontes oficiais."
