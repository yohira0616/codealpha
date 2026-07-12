# claude CLI (claude -p) の薄いラッパー。
# 出力JSONのトップレベルに result / session_id / is_error が入る
# (`echo "..." | claude -p --output-format json` で確認済み)。
require "open3"
require "json"

module ClaudeCli
  class Error < StandardError; end

  # 応答待ちの上限(秒)
  TIMEOUT_SECONDS = 600

  module_function

  # プロンプトを stdin で渡して claude -p を実行し、{ text:, session_id: } を返す。
  # session_id を渡すと --resume で同一セッションを継続する。
  def run(prompt:, session_id: nil)
    command = [ "claude", "-p", "--output-format", "json", "--tools", "" ]
    command += [ "--resume", session_id ] if session_id.present?

    stdout, stderr, status = capture_with_deadline(command, prompt)
    raise Error, "claude CLI が異常終了しました (exit=#{status.exitstatus}): #{stderr.presence || stdout}" unless status.success?

    payload = JSON.parse(stdout)
    raise Error, "claude CLI がエラー応答を返しました: #{payload["result"]}" if payload["is_error"]

    { text: payload["result"], session_id: payload["session_id"] }
  rescue JSON::ParserError => e
    raise Error, "claude CLI の出力をJSONとして解釈できませんでした: #{e.message}"
  end

  # Timeout.timeout + capture3 の組み合わせは、時間切れ後も popen の ensure が
  # wait_thr.join で子プロセスの終了を待ち続けるためタイムアウト保証にならない。
  # popen3 でデッドラインを自前で張り、時間切れは子プロセスを kill してから raise する。
  def capture_with_deadline(command, stdin_data)
    Open3.popen3(*command) do |stdin, stdout, stderr, wait_thr|
      writer = Thread.new do
        stdin.write(stdin_data)
        stdin.close
      rescue Errno::EPIPE
        # 子プロセスが先に死んだ場合は無視(exit status 側で検知される)
      end
      out_reader = Thread.new { stdout.read }
      err_reader = Thread.new { stderr.read }

      unless wait_thr.join(TIMEOUT_SECONDS)
        begin
          Process.kill("KILL", wait_thr.pid)
        rescue Errno::ESRCH
          nil
        end
        raise Error, "claude CLI が #{TIMEOUT_SECONDS} 秒以内に応答しませんでした"
      end

      writer.join
      [ out_reader.value, err_reader.value, wait_thr.value ]
    end
  end
end
