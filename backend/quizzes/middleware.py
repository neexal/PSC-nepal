"""
Custom middleware to exempt CSRF for API endpoints
"""
from django.utils.deprecation import MiddlewareMixin

class DisableCSRFForAPI(MiddlewareMixin):
    """
    Disable CSRF for API endpoints
    """
    def process_request(self, request):
        # Skip CSRF check for API endpoints
        if request.path.startswith('/api/'):
            setattr(request, '_dont_enforce_csrf_checks', True)
        return None

