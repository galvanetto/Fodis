function val = gaussian1D(x, mu, sigma,warea)
%  x     - Input vector
%  mu    - Mean
%  sigma - Standard deviation

    % Evaluate a 1D gaussian.
    val = (warea / (sigma * sqrt(2 * pi))) * exp(-(x - mu).^2 ./ (2 * sigma^2));
end