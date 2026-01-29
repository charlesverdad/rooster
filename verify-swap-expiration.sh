#!/bin/bash
# Manual verification script for swap request expiration

echo "========================================="
echo "Swap Request Expiration Verification"
echo "========================================="
echo ""

echo "This script will:"
echo "1. Run the integration test for swap request expiration"
echo "2. Provide instructions for manual verification"
echo ""

# Check if we're in nix-shell
if ! command -v uv &> /dev/null; then
    echo "ERROR: 'uv' command not found."
    echo "Please run this script from within nix-shell:"
    echo "  nix-shell"
    echo "  ./verify-swap-expiration.sh"
    exit 1
fi

echo "Step 1: Running integration tests..."
echo "-----------------------------------"
cd backend
uv run pytest tests/test_swap_expiration_integration.py -v

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Integration tests PASSED"
else
    echo ""
    echo "✗ Integration tests FAILED"
    exit 1
fi

echo ""
echo "Step 2: Manual verification instructions"
echo "-----------------------------------------"
echo ""
echo "To manually verify swap request expiration:"
echo ""
echo "1. Start the backend server:"
echo "   cd backend"
echo "   uv run uvicorn app.main:app --reload"
echo ""
echo "2. Create a swap request through the API or UI"
echo ""
echo "3. Connect to the database and manually update expires_at:"
echo "   psql rooster_dev"
echo "   UPDATE swap_requests"
echo "   SET expires_at = NOW() - INTERVAL '1 hour'"
echo "   WHERE status = 'PENDING';"
echo ""
echo "4. Run the expiration check (create a management command or call the service method):"
echo "   Example Python script:"
echo "   ---"
echo "   from app.core.database import get_session"
echo "   from app.services.swap_request import SwapRequestService"
echo "   from app.services.notification import NotificationService"
echo ""
echo "   async def run_expiration():"
echo "       async for session in get_session():"
echo "           swap_service = SwapRequestService(session)"
echo "           notification_service = NotificationService(session)"
echo "           "
echo "           # Expire old requests"
echo "           expired_count = await swap_service.expire_old_requests()"
echo "           await session.commit()"
echo "           "
echo "           # Send notifications for expired requests"
echo "           # (Note: This needs to be integrated into the service)"
echo "           print(f'Expired {expired_count} requests')"
echo "   ---"
echo ""
echo "5. Verify in database that status changed to EXPIRED:"
echo "   SELECT id, status, expires_at, created_at"
echo "   FROM swap_requests"
echo "   WHERE status = 'EXPIRED';"
echo ""
echo "6. Verify requester received notification:"
echo "   SELECT n.id, n.type, n.title, n.message, n.created_at"
echo "   FROM notifications n"
echo "   WHERE n.type = 'SWAP_EXPIRED'"
echo "   ORDER BY n.created_at DESC;"
echo ""

echo "========================================="
echo "Verification complete!"
echo "========================================="
