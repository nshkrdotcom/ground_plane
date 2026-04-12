defmodule GroundPlane.Postgres.OutboxInboxTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Postgres.Inbox
  alias GroundPlane.Postgres.Outbox

  test "builds and advances generic outbox entries" do
    now = DateTime.from_unix!(1_700_000_000)

    entry =
      Outbox.new_entry("handoff.submit", %{intent_id: "intent_1"},
        now: now,
        dedupe_key: "dedupe_1"
      )

    assert entry.state == "pending"

    entry = Outbox.mark_dispatched(entry, now)
    assert entry.state == "dispatched"
    assert entry.attempt_count == 1

    entry = Outbox.mark_completed(entry, now)
    assert entry.state == "completed"
  end

  test "builds and applies inbox entries" do
    entry =
      Inbox.new_entry("execution_plane", %{receipt_id: "receipt_1"}, idempotency_key: "idem_1")

    assert entry.state == "received"

    entry = Inbox.mark_applied(entry, DateTime.from_unix!(1_700_000_000))
    assert entry.state == "applied"
  end
end
