function z = alssmooth(y, lambda, p) 
% Estimate baseline with asymmetric least squares 
% Good starting points for constants:
% Lambda: 1e4
% p: 1e-2 -> 1e-3
m = length(y); 
D = diff(speye(m), 2); 
w = ones(m, 1); 
for it = 1:50 
    W = spdiags(w, 0, m, m); 
    C = chol(W + lambda * D' * D); 
    z = C \ (C' \ (w .* y)); 
    w = p * (y > z) + (1 - p) * (y < z);
end

