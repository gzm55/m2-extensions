# -----------------------------------------------------------------------------
# Optional Environment Variable
#
#   MAVEN_SKIP_M2_EXT - if not empty, skip loading .m2/ext directory
#   M2_EXTENSIONS_HOME - local clone of m2-extensions
# -----------------------------------------------------------------------------
if [ -z "${MAVEN_SKIP_M2_EXT-}" ] \
   && [ -d "${HOME-}" ] \
   && [ -f "${HOME-}/.m2/extensions.xml" ]; then

  export MAVEN_SKIP_M2_EXT=true

  if ! diff "$HOME/.m2/extensions.xml" \
            "$HOME/.m2/ext/extensions.xml" >/dev/null 2>/dev/null; then
    if [ ! -f "${M2_EXTENSIONS_HOME:=$HOME/.m2/m2-extension}/pom.xml" ] \
       && [ -d "${TMPDIR:=/tmp}" ] && [ "$(cd -- "$TMPDIR"; pwd)" != / ]; then
      M2_EXTENSIONS_HOME=$(mktemp -d) || echo "[WARN] mktemp fail!"
      if [ -d "$M2_EXTENSIONS_HOME" ]; then
        if command -v git >/dev/null 2>/dev/null; then
          if git clone --help | grep -q -- --depth; then
            git clone --depth 1
              https://github.com/gzm55/m2-extensions.git "$M2_EXTENSIONS_HOME"
          else
            git clone \
              https://github.com/gzm55/m2-extensions.git "$M2_EXTENSIONS_HOME"
          fi
        fi \
        || rm -rf -- "${TMPDIR:?}/$(basename -- "M2_EXTENSIONS_HOME")" \
        || echo "[WARN] fail to cleanup temp dir: \"$M2_EXTENSIONS_HOME\""
      fi
    fi

    if [ -f "$M2_EXTENSIONS_HOME/pom.xml" ]; then
      ( set -e
        cd -- "$M2_EXTENSIONS_HOME" || exit 1
        mvnbin=./mvnw
        if command -v mvn >/dev/null 2>/dev/null \
           && mvn --version | head -n 1 | cut -d ' ' -f 3 \
              | grep -q '^\([1-9][0-9]+\|[4-9]\|3\.[1-9][0-9]+\|3\.[3-9]\)'
        then mvnbin=mvn
	elif [ "$(basename -- "$0")" = mvnw ] \
           && "$0" --version | head -n 1 | cut -d ' ' -f 3 \
              | grep -q '^\([1-9][0-9]+\|[4-9]\|3\.[1-9][0-9]+\|3\.[3-9]\)'
        then mvnbin="$0"
        fi
        "$mvnbin" clean install
      ) || echo "[WARN] fail to deploy m2-extension"
      if [ "$(dirname -- "M2_EXTENSIONS_HOME")" = "TMPDIR" ]; then
        rm -rf -- "${TMPDIR:?}/$(basename -- "M2_EXTENSIONS_HOME")" \
        || echo "[WARN] fail to cleanup temp dir: \"$M2_EXTENSIONS_HOME\""
      fi
    else
      echo "[WARN] Can't locate \$M2_EXTENSIONS_HOME nor download a temp one!"
      echo "[WARN] Skip load user extensions in .m2/ext/"
    fi
  fi

  if diff "$HOME/.m2/extensions.xml" \
          "$HOME/.m2/ext/extensions.xml" >/dev/null 2>/dev/null; then

    MAVEN_OPTS="$( CLEAN_MAVEN_OPTS='' LAST_EXT=''
      for i in $MAVEN_OPTS; do
        if [ "${i#-Dmaven.ext.class.path=}" = "$i" ]; then
          CLEAN_MAVEN_OPTS="$CLEAN_MAVEN_OPTS $i"
        else
          LAST_EXT="${i#-Dmaven.ext.class.path=}"
        fi
      done
      printf "%s -Dmaven.ext.class.path=%s" \
             "${CLEAN_MAVEN_OPTS# }" "${LAST_EXT:+$LAST_EXT:}"
    )$(find "$HOME/.m2/ext" -name '*.jar' | xargs printf '%s:')"
    MAVEN_OPTS="${MAVEN_OPTS%:}"
    MAVEN_OPTS="${MAVEN_OPTS% -Dmaven.ext.class.path=}"
    MAVEN_OPTS="${MAVEN_OPTS# }"
    [ -n "$MAVEN_OPTS" ] || unset MAVEN_OPTS

  else
    printf "%s\\n" "[WARN] Can't resolve .m2/extensions.xml"
    printf "%s\\n" "[WARN] Skip load user extensions in .m2/ext/"
  fi
fi
